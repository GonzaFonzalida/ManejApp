# Lista de Verificación de Testing - ManejApp

## ✅ Cambios Implementados

### 1. Fondo Blanco en Avatar
- **Archivo**: `lib/screens/home_screen.dart`
- **Cambio**: CircleAvatar ahora tiene fondo blanco en lugar de azul
- **Testing**: Verificar que los avatares de instructores se vean con fondo blanco

### 2. Edición de Perfil Funcional
- **Archivos**: 
  - `lib/screens/editar_perfil_screen.dart`
  - `lib/services/api_service.dart`
- **Cambios**:
  - Agregado método `updateUser()` en API service
  - Actualizada lógica de guardado para actualizar usuario e instructor
  - Campo "Zona donde vive" cambiado a "Ubicación"
- **Testing**:
  1. Ir a Perfil → Editar Perfil
  2. Cambiar nombre, descripción y ubicación
  3. Presionar "Guardar"
  4. Verificar que se muestre mensaje de éxito
  5. Verificar que los cambios se reflejen en el perfil

### 3. Campo de Ubicación
- **Archivos**:
  - `lib/models/instructor.dart`
  - `lib/screens/editar_perfil_screen.dart`
- **Cambios**:
  - Agregado campo `location` al modelo User
  - Campo de ubicación en formulario de edición
- **Testing**:
  1. Editar perfil y agregar ubicación (ej: "Tortuguitas, Buenos Aires")
  2. Guardar y verificar que se almacene correctamente

### 4. Mapa con Instructores Cercanos
- **Archivo**: `lib/screens/home_screen.dart`
- **Cambios**:
  - Geocodificación automática de ubicaciones de instructores
  - Marcadores rojos en el mapa para instructores
  - Marcador azul para ubicación actual
  - Botón "Buscar instructor" filtra por cercanía
  - Cálculo de distancia usando fórmula de Haversine
- **Testing**:
  1. Abrir pantalla de inicio (Home)
  2. Verificar que el mapa muestre marcadores rojos para instructores con ubicación
  3. Ingresar una dirección y presionar buscar
  4. Verificar que el mapa se centre en la dirección
  5. Presionar botón "Buscar instructor"
  6. Verificar que la lista se ordene por cercanía
  7. Usar botón de "Mi ubicación" para obtener ubicación actual

## 📋 Pasos de Testing Manual

### Test 1: Flujo Completo de Instructor
1. Registrarse como instructor
2. Completar perfil con ubicación
3. Ir a "Editar Perfil"
4. Cambiar ubicación a una zona específica (ej: "Grand Bourg, Buenos Aires")
5. Guardar cambios
6. Verificar que se guarde correctamente

### Test 2: Flujo Completo de Estudiante
1. Registrarse como estudiante
2. Ir a pantalla de inicio
3. Ingresar dirección en buscador
4. Presionar "Buscar instructor"
5. Verificar que se muestren instructores ordenados por cercanía
6. Verificar que el mapa muestre marcadores de instructores

### Test 3: Búsqueda por Ubicación
1. Abrir app como estudiante
2. Permitir permisos de ubicación
3. Presionar botón "Mi ubicación"
4. Verificar que el mapa se centre en ubicación actual
5. Presionar "Buscar instructor"
6. Verificar que se muestren instructores cercanos

## 🐛 Posibles Problemas y Soluciones

### Problema: No se muestran marcadores de instructores
**Solución**: 
- Verificar que los instructores tengan ubicación configurada en su perfil
- Verificar conexión a internet (se usa API de Nominatim para geocodificación)
- Revisar logs para errores de geocodificación

### Problema: Error al guardar perfil
**Solución**:
- Verificar que el backend esté corriendo
- Verificar que la ruta PUT /api/v1/users/:id exista en el backend
- Verificar que la ruta PUT /api/v1/instructors/:id exista en el backend

### Problema: Ubicación no se geocodifica
**Solución**:
- Usar formato: "Ciudad, Provincia, Argentina"
- Ejemplo: "Tortuguitas, Buenos Aires, Argentina"
- Verificar conexión a internet

## 📝 Notas Importantes

1. **Geocodificación**: Se usa la API gratuita de Nominatim (OpenStreetMap). Tiene límite de 1 request por segundo.

2. **Ubicaciones**: Para mejores resultados, usar formato completo:
   - ✅ "Tortuguitas, Buenos Aires, Argentina"
   - ✅ "Grand Bourg, Malvinas Argentinas, Buenos Aires"
   - ❌ "Tortuguitas" (puede no encontrar)

3. **Permisos**: La app necesita permisos de ubicación para usar "Mi ubicación"

4. **Backend**: Asegurarse que el backend tenga:
   - Campo `location` en tabla `users`
   - Ruta PUT `/api/v1/users/:id` para actualizar usuario
   - Ruta PUT `/api/v1/instructors/:id` para actualizar instructor

## ✨ Funcionalidades Nuevas

1. **Mapa Interactivo**: Muestra ubicación actual y ubicaciones de instructores
2. **Búsqueda por Cercanía**: Ordena instructores por distancia
3. **Geocodificación Automática**: Convierte direcciones de texto a coordenadas
4. **Marcadores Diferenciados**: 
   - Azul: Tu ubicación
   - Rojo: Instructores

## 🎯 Próximos Pasos Sugeridos

1. Agregar tooltips en marcadores del mapa con nombre del instructor
2. Mostrar distancia en km en cada card de instructor
3. Agregar filtro por radio de distancia (ej: "Mostrar instructores a menos de 5km")
4. Cachear geocodificaciones para evitar llamadas repetidas a la API
5. Agregar indicador de carga mientras se geocodifican ubicaciones
