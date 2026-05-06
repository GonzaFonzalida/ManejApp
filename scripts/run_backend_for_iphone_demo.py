#!/usr/bin/env python3
"""
ManejApp — preparar el backend en la Mac para probar la app Flutter desde un iPhone en la misma red.

Problema que resuelve: en el iPhone, 127.0.0.1/localhost es el propio teléfono, no tu Mac.
Este script detecta la IP LAN, comprueba /api/v1/config y opcionalmente arranca `pnpm run dev`.

El servidor ya escucha en 0.0.0.0 (src/index.ts); no hace falta bind extra.

Uso típico:
  cd /ruta/al/ManejApp   # carpeta que contiene package.json de Node
  python3 scripts/run_backend_for_iphone_demo.py

Solo mostrar URLs sin arrancar el servidor:
  python3 scripts/run_backend_for_iphone_demo.py --no-start

Puerto distinto:
  python3 scripts/run_backend_for_iphone_demo.py --port 3001
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import signal
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Optional


def log(msg: str, *, err: bool = False) -> None:
    prefix = "[!] " if err else "[*] "
    f = sys.stderr if err else sys.stdout
    print(prefix + msg, file=f, flush=True)


def script_backend_root() -> Path:
    """Directorio raíz del backend (padre de scripts/)."""
    return Path(__file__).resolve().parent.parent


def read_port_from_dotenv(backend_root: Path) -> Optional[int]:
    env_path = backend_root / ".env"
    if not env_path.is_file():
        return None
    try:
        text = env_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        m = re.match(r'^PORT\s*=\s*"?(\d+)"?\s*$', line, re.I)
        if m:
            return int(m.group(1))
    return None


def detect_lan_ip() -> Optional[str]:
    """IP IPv4 de la interfaz por defecto (macOS); fallbacks en0..en3."""
    try:
        out = subprocess.run(
            ["route", "-n", "get", "default"],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
        iface: Optional[str] = None
        for line in (out.stdout or "").splitlines():
            if "interface:" in line:
                parts = line.split("interface:")
                if len(parts) >= 2:
                    iface = parts[1].strip()
                break
        if iface:
            out2 = subprocess.run(
                ["ipconfig", "getifaddr", iface],
                capture_output=True,
                text=True,
                timeout=5,
                check=False,
            )
            ip = (out2.stdout or "").strip()
            if ip and _looks_like_ipv4(ip):
                return ip
    except (OSError, subprocess.TimeoutExpired):
        pass

    for iface in ("en0", "en1", "en2", "en3"):
        try:
            out2 = subprocess.run(
                ["ipconfig", "getifaddr", iface],
                capture_output=True,
                text=True,
                timeout=5,
                check=False,
            )
            ip = (out2.stdout or "").strip()
            if ip and _looks_like_ipv4(ip):
                return ip
        except (OSError, subprocess.TimeoutExpired):
            continue
    return None


def _looks_like_ipv4(s: str) -> bool:
    parts = s.split(".")
    if len(parts) != 4:
        return False
    try:
        return all(0 <= int(p) <= 255 for p in parts)
    except ValueError:
        return False


def http_get_status(url: str, timeout: float = 3.0) -> tuple[bool, int, str]:
    """GET URL; devuelve (ok_200, status_or_0, mensaje)."""
    try:
        req = urllib.request.Request(url, method="GET")
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            code = resp.getcode()
            body = resp.read(512).decode("utf-8", errors="replace")
            return code == 200, code, body[:200]
    except urllib.error.HTTPError as e:
        return False, e.code, str(e.reason)
    except urllib.error.URLError as e:
        return False, 0, str(e.reason)
    except OSError as e:
        return False, 0, str(e)


def tcp_connect(host: str, port: int, timeout: float = 2.0) -> bool:
    import socket

    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except OSError:
        return False


def config_url(host: str, port: int) -> str:
    return f"http://{host}:{port}/api/v1/config"


def print_summary_block(lan_ip: str, port: int) -> None:
    """Imprime API_URL y comando Flutter (siempre útil aunque el backend no esté arriba)."""
    api_base = f"http://{lan_ip}:{port}"
    url_lan = config_url(lan_ip, port)
    flutter_cmd = (
        f'flutter run --release -d <DEVICE_ID> --dart-define=API_URL={api_base}'
    )
    print(flush=True)
    print("========== RESUMEN (iPhone / LAN) ==========", flush=True)
    print(f"  API_URL (base, sin /api/v1):  {api_base}", flush=True)
    print(f"  Test en Safari (iPhone):      {url_lan}", flush=True)
    print(flush=True)
    print("  Listá dispositivos:", flush=True)
    print("    cd ../ManejApp-frontend   # o la ruta de tu frontend", flush=True)
    print("    flutter devices", flush=True)
    print(flush=True)
    print("  Comando Flutter (copiar y pegar; reemplazá <DEVICE_ID>):", flush=True)
    print(f"    {flutter_cmd}", flush=True)
    print("============================================", flush=True)
    print(flush=True)


def ensure_tools(backend_root: Path) -> None:
    if not (backend_root / "package.json").is_file():
        log(f"No está package.json en {backend_root}", err=True)
        sys.exit(2)
    if shutil.which("pnpm") is None:
        log("No se encontró `pnpm` en PATH. Instalá pnpm o usá el mismo entorno que para desarrollo.", err=True)
        sys.exit(2)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Backend ManejApp listo para iPhone en LAN (detecta IP, verifica /api/v1/config, arranca pnpm run dev)."
    )
    parser.add_argument(
        "--backend-dir",
        type=Path,
        default=None,
        help="Carpeta del backend (default: padre de scripts/).",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=None,
        help="Puerto HTTP (default: PORT en .env o 3099).",
    )
    parser.add_argument(
        "--no-start",
        action="store_true",
        help="No arrancar el servidor; solo detectar IP, comprobar estado e imprimir comandos.",
    )
    parser.add_argument(
        "--no-wait",
        action="store_true",
        help="Si arrancás el servidor, salir en cuanto responda /config (no esperar al proceso; útil para scripts).",
    )
    args = parser.parse_args()

    backend_root = (args.backend_dir or script_backend_root()).resolve()
    ensure_tools(backend_root)

    port = args.port
    if port is None:
        port = read_port_from_dotenv(backend_root)
    if port is None:
        port = 3099

    lan_ip = detect_lan_ip()
    if not lan_ip:
        log(
            "No se pudo detectar una IP LAN (Wi‑Fi/Ethernet). Conectate a la red e intentá de nuevo.",
            err=True,
        )
        sys.exit(3)

    url_local = config_url("127.0.0.1", port)
    url_lan = config_url(lan_ip, port)

    log(f"IP LAN detectada: {lan_ip}")
    log(f"Puerto: {port}")
    log(f"URL local:  {url_local}")
    log(f"URL LAN:    {url_lan}")

    ok_local, code_local, msg_local = http_get_status(url_local)
    if ok_local:
        log("Backend ya responde en localhost (/api/v1/config OK).")
    else:
        log(
            f"Backend no responde en localhost (status={code_local}): {msg_local}",
            err=not args.no_start,
        )

    if ok_local:
        if tcp_connect(lan_ip, port):
            ok_lan, code_lan, msg_lan = http_get_status(url_lan)
            if ok_lan:
                log("Acceso por IP LAN verificado (HTTP /api/v1/config OK).")
            else:
                log(
                    f"TCP a {lan_ip}:{port} OK pero HTTP falló (status={code_lan}): {msg_lan}. "
                    "Revisá firewall de macOS o proxy.",
                    err=True,
                )
        else:
            log(
                f"No se pudo abrir TCP a {lan_ip}:{port} desde esta Mac. "
                "Si el servidor solo escuchara en 127.0.0.1 fallaría aquí; ManejApp usa 0.0.0.0 en src/index.ts. "
                "Comprobá que el proceso sea el backend correcto y el puerto.",
                err=True,
            )
    elif not args.no_start:
        log("Se intentará arrancar el backend con `pnpm run dev`…")

    child: Optional[subprocess.Popen[str]] = None
    if not ok_local and not args.no_start:
        os.chdir(backend_root)
        # Heredar stdin/stdout/stderr para ver logs de ts-node-dev en la misma terminal
        child = subprocess.Popen(
            ["pnpm", "run", "dev"],
            cwd=str(backend_root),
            stdin=sys.stdin,
            stdout=sys.stdout,
            stderr=sys.stderr,
        )

        deadline = time.time() + 90.0
        started = False
        while time.time() < deadline:
            ok, _, _ = http_get_status(url_local)
            if ok:
                started = True
                log("Backend respondió en localhost.")
                break
            if child.poll() is not None:
                log("El proceso `pnpm run dev` terminó antes de responder. Revisá .env y DATABASE_URL.", err=True)
                sys.exit(4)
            time.sleep(1)

        if not started:
            log("Timeout esperando /api/v1/config en localhost.", err=True)
            if child and child.poll() is None:
                child.terminate()
                try:
                    child.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    child.kill()
            sys.exit(4)

    # Re-evaluar después de un posible arranque
    ok_local, code_local, msg_local = http_get_status(url_local)
    if not ok_local:
        log(f"/api/v1/config no responde en localhost (status={code_local}): {msg_local}", err=True)
        if code_local == 404 or code_local == 0:
            log(
                "Si el puerto está ocupado por otra app, probá: --port 3001 "
                "o detené el proceso que usa el puerto.",
                err=True,
            )
        if child and child.poll() is None:
            child.terminate()
        if args.no_start:
            log(
                "Con --no-start no se arrancó el servidor; levantá ManejApp con `pnpm run dev` y reintentá.",
                err=True,
            )
        print_summary_block(lan_ip, port)
        if args.no_start:
            sys.exit(6)
        sys.exit(5)

    ok_lan_http, code_lan, msg_lan = http_get_status(url_lan)
    if ok_lan_http:
        log(f"Verificación LAN OK: {url_lan}")
    else:
        log(
            f"Aviso: desde esta Mac HTTP a {url_lan} devolvió status={code_lan} ({msg_lan}). "
            "El iPhone puede funcionar igual; si no, revisá firewall.",
            err=True,
        )

    print_summary_block(lan_ip, port)

    if child is None:
        # Ya estaba corriendo (externo)
        if args.no_start:
            sys.exit(0)
        log("El backend ya estaba en marcha (no iniciado por este script). Nada más que hacer.")
        sys.exit(0)

    if args.no_wait:
        log("Servidor en segundo plano (PID {}). Usá kill para detenerlo.".format(child.pid))
        sys.exit(0)

    def _stop(_sig=None, _frame=None):
        if child and child.poll() is None:
            child.terminate()

    signal.signal(signal.SIGINT, _stop)
    signal.signal(signal.SIGTERM, _stop)

    log("Mostrando logs del backend (Ctrl+C para detener)…")
    rc = child.wait()
    sys.exit(rc if rc is not None else 0)


if __name__ == "__main__":
    main()
