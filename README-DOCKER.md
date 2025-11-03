# 🐳 Despliegue con Docker - ManejApp Backend

## Archivos creados

- `Dockerfile` - Imagen optimizada multi-stage para el backend
- `docker-compose.yml` - Orquestación con PostgreSQL
- `.dockerignore` - Exclusión de archivos innecesarios
- `start.sh` - Script de inicio con migraciones automáticas

## 🚀 Despliegue rápido

### Con Docker Compose (Recomendado)

```bash
# Construir y ejecutar todo el stack
docker-compose up --build

# En modo detached (background)
docker-compose up -d --build
```

### Solo el backend (requiere BD externa)

```bash
# Construir imagen
docker build -t manejapp-backend .

# Ejecutar contenedor
docker run -p 3000:3000 \
  -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
  -e JWT_SECRET="your-secret-key" \
  manejapp-backend
```

## ⚙️ Variables de entorno requeridas

Crea un archivo `.env` basado en `.env.example` o configura estas variables:

```bash
DATABASE_URL=postgresql://postgres:password@postgres:5432/manejapp
JWT_SECRET=your-super-secret-jwt-key-minimum-32-characters-long
JWT_REFRESH_SECRET=your-super-secret-refresh-key-minimum-32-characters-long
COOKIE_SECRET=your-super-secret-cookie-key-minimum-32-characters-long
```

## 📝 Comandos útiles

```bash
# Ver logs del backend
docker-compose logs -f backend

# Ver logs de la base de datos
docker-compose logs -f postgres

# Ejecutar migraciones manualmente
docker-compose exec backend npx prisma migrate deploy

# Acceder al contenedor del backend
docker-compose exec backend sh

# Detener servicios
docker-compose down

# Detener y eliminar volúmenes
docker-compose down -v
```

## 🔧 Características del Dockerfile

- **Multi-stage build** para optimizar tamaño
- **Usuario no-root** para seguridad
- **Prisma** configurado automáticamente
- **Logs persistentes** en volumen
- **Migraciones automáticas** al inicio

## 🌐 Acceso

Una vez desplegado:
- Backend: http://localhost:3000
- Base de datos: localhost:5432

## 📊 Monitoreo

Los logs se almacenan en:
- Contenedor: `/app/logs/`
- Host: `./logs/`