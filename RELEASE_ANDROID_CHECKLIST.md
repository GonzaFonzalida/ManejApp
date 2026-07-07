# ManejApp Android — Internal Testing (Google Play)

Checklist para subir la **primera beta** a **Internal Testing** (no producción).

## Prerrequisitos locales

### 1. Keystore de upload (real)

```bash
cd ManejApp-frontend/android
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

- **No** usar `upload-keystore-demo.jks` para Play.
- **No** commitear `upload-keystore.jks` ni `key.properties`.

### 2. `key.properties`

```bash
cp android/key.properties.example android/key.properties
# Editar contraseñas y storeFile
```

Ejemplo:

```properties
storePassword=TU_PASSWORD
keyPassword=TU_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

`android/app/build.gradle.kts` solo firma release si `key.properties` apunta a un keystore **existente y no demo**.

### 3. SHA-1 del upload keystore (OAuth Android Release)

```bash
keytool -list -v -keystore android/upload-keystore.jks -alias upload
```

En **Google Cloud Console** → APIs & Services → Credentials → **Create OAuth client ID**:

| Campo | Valor |
|--------|--------|
| Tipo | Android |
| Nombre | ManejApp Android Release Upload |
| Package | `com.manejapp.app` |
| SHA-1 | *(salida de keytool del keystore real)* |

Mantener también el cliente **Android Debug** con el SHA-1 de debug local.

### 4. Build AAB beta

```bash
cd ManejApp-frontend
flutter clean
flutter pub get
flutter build appbundle --release \
  --dart-define=API_URL=https://manejapp-1.onrender.com
```

Salida: `build/app/outputs/bundle/release/app-release.aab`

**API_URL:** en release, si no pasás `--dart-define`, el default ya es `https://manejapp-1.onrender.com` (`config_service.dart`). Igual se recomienda pasarlo explícito en CI y builds de beta.

---

## Google Play Console (manual)

### A. Crear la app

1. [Play Console](https://play.google.com/console) → **Crear app**.
2. Nombre: **ManejApp**.
3. Tipo: App / Gratis (ajustar según modelo).
4. Declaraciones iniciales (políticas, público, etc.).

### B. Activar Play App Signing

1. **Release** → **Setup** → **App signing**.
2. Elegir **Let Google manage and protect your app signing key** (recomendado).
3. Subir el primer AAB firmado con tu **upload key**; Google re-firma con la app signing key.

### C. SHA-1 de Play App Signing (OAuth)

Tras el primer upload:

1. **Release** → **Setup** → **App signing**.
2. Copiar **SHA-1 certificate fingerprint** de **App signing key certificate**.
3. En Google Cloud, crear **otro** OAuth client Android (o agregar SHA-1 adicional si la consola lo permite):

| Campo | Valor |
|--------|--------|
| Nombre | ManejApp Android Play App Signing |
| Package | `com.manejapp.app` |
| SHA-1 | *(Play App Signing SHA-1)* |

Sin este SHA-1, **Google Sign-In falla en builds instalados desde Play** aunque funcione en debug/sideload.

### D. Internal Testing

1. **Release** → **Testing** → **Internal testing**.
2. **Create new release** → subir `app-release.aab`.
3. Notas de versión (mínimo para testers).
4. **Review release** → **Start rollout to Internal testing**.
5. Agregar testers (lista de emails o Google Group).

### E. Store listing mínimo

- **App name**, **short description**, **full description**.
- **Icono** 512×512.
- **Feature graphic** 1024×500.
- Al menos **2 screenshots** (teléfono).
- **Categoría** (Educación / Estilo de vida).
- **Email de contacto** del desarrollador.

### F. Política de privacidad

- URL pública obligatoria (ej. página en tu sitio o GitHub Pages).
- Debe describir datos recolectados (email, ubicación si aplica, Google Sign-In, etc.).

### G. Data safety

Completar el formulario en Play Console alineado con la app real:

- Datos de cuenta (email, nombre).
- Ubicación (si se usa para instructores).
- Datos de autenticación (Google).
- Indicar si se comparten con terceros (Mercado Pago, etc. solo si aplica en la versión beta).

### H. OAuth consent screen (Google Cloud)

Si el proyecto OAuth está en modo **Testing**:

- Agregar emails de internal testers en **Test users**.
- Sin esto, usuarios fuera de la lista verán `access_denied` en Sign-In.

---

## QA post-install desde Play

Instalar desde el **enlace de Internal testing** (no sideload del mismo AAB sin pasar por Play si querés validar App Signing + OAuth Play SHA-1).

- [ ] App abre sin crash.
- [ ] API responde (`https://manejapp-1.onrender.com`).
- [ ] **Continuar con Google** sin `ApiException: 10` / `DEVELOPER_ERROR`.
- [ ] Login → dashboard (usuario existente) o choose role (usuario nuevo).
- [ ] Onboarding alumno completo.
- [ ] Logout → re-login Google → dashboard directo.
- [ ] Maps carga (clave en `android/local.properties` → `GOOGLE_MAPS_API_KEY`).
- [ ] Sin errores de sesión en home/perfil.

---

## Comandos de verificación pre-upload

```bash
cd ManejApp-frontend
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_URL=https://manejapp-1.onrender.com
flutter build appbundle --release --dart-define=API_URL=https://manejapp-1.onrender.com
```

---

## Archivos que no deben ir al repo

- `android/key.properties`
- `android/upload-keystore.jks` (keystore real)
- `android/local.properties` (Maps API key)
- `upload-keystore-demo.jks` puede quedar como referencia local; está en `.gitignore` vía `**/*.jks`
