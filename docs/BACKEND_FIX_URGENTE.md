# 🚨 FIX URGENTE PARA BACKEND - SERVIR ARCHIVOS ESTÁTICOS

## Problema
Las imágenes se suben correctamente al servidor pero **NO se pueden ver** porque el backend no está sirviendo los archivos estáticos.

## Solución

### 1. En tu archivo principal del backend (app.ts o main.ts):

```typescript
import express from 'express';
import path from 'path';

const app = express();

// ✅ AGREGAR ESTA LÍNEA ANTES DE LAS RUTAS
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// ... resto de tu código
```

### 2. Verificar que la carpeta uploads existe:

```bash
mkdir -p uploads/profiles
```

### 3. Verificar permisos (Linux/Mac):

```bash
chmod -R 755 uploads
```

## Verificación

Después de agregar el código, probá acceder a:
```
http://192.168.0.3:3000/uploads/profiles/profile_1_1762224777687.jpg
```

Si ves la imagen, está funcionando. Si no, revisá:
- Que la carpeta `uploads` esté en la raíz del proyecto
- Que el path en `path.join(__dirname, '../uploads')` sea correcto
- Que el servidor se haya reiniciado después del cambio

## Alternativa con CORS

Si usás CORS, asegurate de permitir acceso a /uploads:

```typescript
import cors from 'cors';

app.use(cors({
  origin: '*', // O tu dominio específico
  credentials: true
}));

app.use('/uploads', express.static(path.join(__dirname, '../uploads')));
```

## Sin esto, las imágenes NUNCA se verán en el frontend
