# Instrucciones para Debug

## Problema 1: Descripción no se guarda

### Pasos para verificar:
1. Ejecuta la app con `flutter run`
2. Ve a tu perfil y toca "Editar Perfil"
3. Escribe algo en el campo "Descripción"
4. Toca "Guardar Cambios"
5. Busca en los logs de la consola estos mensajes:

```
=== GUARDANDO INSTRUCTOR ====
instructorId: [número]
description: [tu texto]
=== UPDATE INSTRUCTOR ===
URL: http://192.168.0.3:3000/api/v1/instructors/[id]
Data: {"description":"tu texto"}
Response status: [código]
Response body: [respuesta]
```

### Preguntas para el backend:
- ¿El endpoint `PUT /api/v1/instructors/:id` acepta el campo `description`?
- ¿Está guardando correctamente en la base de datos?
- ¿Qué devuelve en el response body?
- ¿El endpoint `GET /api/v1/instructors` incluye el campo `description` en la respuesta?

## Problema 2: Botón de cambiar foto no aparece

### Ubicación del botón:
El botón está en la pantalla "Editar Perfil" (NO en la pantalla de perfil principal).

### Cómo llegar:
1. Ve a tu perfil (ícono de persona en la barra inferior)
2. Toca el botón "Editar Perfil" (botón azul debajo de tu nombre)
3. Deberías ver arriba un círculo grande azul con gradiente
4. En la esquina inferior derecha del círculo hay un ícono de cámara blanco
5. Debajo dice "Toca para cambiar foto"

### Si no lo ves:
1. Cierra completamente la app
2. Ejecuta: `flutter clean && flutter pub get`
3. Ejecuta: `flutter run`
4. Espera a que compile completamente
5. Vuelve a intentar

### Verificar que la imagen se sube:
Cuando selecciones una imagen, busca en los logs:
```
Subiendo imagen - userId: [id], path: [ruta]
Enviando request...
Response status: [código]
Response body: [respuesta]
```

### Preguntas para el backend:
- ¿El endpoint `POST /api/v1/users/:id/upload-profile-image` está funcionando?
- ¿Devuelve el campo `profileImage` con la ruta relativa (ej: `/uploads/profile-images/xxx.jpg`)?
- ¿El endpoint `GET /api/v1/users/:id` devuelve el campo `profileImage` en la respuesta?

## Comandos útiles:

### Limpiar y recompilar:
```bash
cd ManejApp
flutter clean
flutter pub get
flutter run
```

### Ver logs en tiempo real:
```bash
flutter run --verbose
```

### Filtrar logs específicos:
En Windows PowerShell:
```powershell
flutter run 2>&1 | Select-String "GUARDANDO|UPDATE INSTRUCTOR|Subiendo imagen"
```
