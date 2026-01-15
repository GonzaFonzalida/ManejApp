# ManejApp

Aplicación de gestión de clases de conducción con integración de Mercado Pago.

## Configuración de Desarrollo

### Mercado Pago

Para desarrollar con Mercado Pago, necesitas configurar URLs públicas ya que Mercado Pago no puede acceder a `localhost`.

#### Opción 1: Usar ngrok (Recomendado)

**Método automático (recomendado):**
```bash
npm run dev:ngrok
```
Esto iniciará tanto tu aplicación como ngrok automáticamente.

**Método manual:**
1. Instala ngrok desde https://ngrok.com/
2. Inicia tu aplicación local:
   ```bash
   npm run dev
   ```
3. En otra terminal, inicia ngrok:
   ```bash
   npm run ngrok
   ```
4. Copia la URL HTTPS que ngrok te proporciona (ej: `https://abc123.ngrok.io`)
5. Actualiza tu archivo `.env`:
   ```env
   APP_URL_PUBLIC="https://abc123.ngrok.io"
   ```

#### Opción 2: Usar un servicio de tunneling alternativo

Puedes usar servicios como:
- LocalTunnel: `npx localtunnel --port 3000`
- Serveo: `ssh -R 80:localhost:3000 serveo.net`

#### Variables de Entorno

Asegúrate de tener estas variables en tu `.env`:

```env
# Mercado Pago
MERCADOPAGO_ACCESS_TOKEN="tu_access_token"
MERCADOPAGO_PUBLIC_KEY="tu_public_key"
APP_URL="http://localhost:3000"
APP_URL_PUBLIC="https://tu-url-publica"  # Solo para desarrollo
```

### Cómo funciona

- En **desarrollo**: Si `APP_URL_PUBLIC` está configurada, se usa para las `back_urls` de Mercado Pago
- En **producción**: Se usa `APP_URL` (debe ser una URL HTTPS válida)

## Scripts Disponibles

- `npm run dev` - Inicia el servidor en modo desarrollo
- `npm run dev:ngrok` - Inicia el servidor + ngrok automáticamente
- `npm run dev:tunnel` - Inicia el servidor + localtunnel automáticamente
- `npm run ngrok` - Inicia solo ngrok en el puerto 3000
- `npm run tunnel` - Inicia solo localtunnel en el puerto 3000
- `npm run build` - Construye la aplicación para producción
- `npm start` - Inicia el servidor en producción

## API Endpoints

### Pagos

- `POST /payments/mercadopago` - **Crear pago con Mercado Pago (con comisiones automáticas)**
- `POST /payments/mercadopago/preference` - Crear preferencia de Mercado Pago
- `GET /payments/:id` - Obtener pago por ID

### Sistema de Comisiones *(Activo desde enero 2026)*

- `POST /payments/with-commission` - Crear pago con comisión (legacy)
- `GET /payments/commission-report` - Reporte de comisiones de la app
- `GET /payments/instructor/:id/earnings` - Ganancias por instructor

## Solución de Problemas

### Error: "auto_return invalid. back_url.success must be defined"

Este error ocurre cuando Mercado Pago no puede validar las URLs de `back_urls`. Soluciones:

1. **Desarrollo**: Configura `APP_URL_PUBLIC` con una URL pública (ngrok)
2. **Producción**: Asegúrate de que `APP_URL` sea HTTPS y accesible públicamente

### Error: "Invalid URL" en Mercado Pago

- Verifica que las URLs sean HTTPS en producción
- Asegúrate de que el dominio esté accesible desde internet
- Revisa que no haya errores de sintaxis en las URLs