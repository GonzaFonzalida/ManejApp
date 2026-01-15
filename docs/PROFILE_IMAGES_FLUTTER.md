# 📸 ManejApp - Integración de Imágenes de Perfil en Flutter

## 📋 **Resumen**

Esta documentación explica cómo integrar el sistema de imágenes de perfil desde Flutter con la API de ManejApp.

## 🔗 **Endpoints de la API**

### **Base URL**
```
http://tu-servidor:3000/api/v1
```

### **1. Subir Imagen de Perfil**
```http
POST /users/profile-image
Content-Type: multipart/form-data
Authorization: Bearer {token}
```

**Parámetros:**
- `profileImage`: Archivo de imagen (jpeg, jpg, png, gif, webp)
- **Límite**: 5MB máximo

**Respuesta Exitosa (200):**
```json
{
  "message": "Imagen de perfil actualizada exitosamente",
  "user": {
    "id": 123,
    "name": "Juan",
    "surname": "Pérez",
    "email": "juan@example.com",
    "profileImage": "profile-123-1642598400000-abc123.jpg"
  },
  "imageUrl": "/api/v1/users/profile-image/profile-123-1642598400000-abc123.jpg"
}
```

### **2. Eliminar Imagen de Perfil**
```http
DELETE /users/profile-image
Authorization: Bearer {token}
```

**Respuesta Exitosa (200):**
```json
{
  "message": "Imagen de perfil eliminada exitosamente",
  "user": {
    "id": 123,
    "name": "Juan",
    "surname": "Pérez",
    "profileImage": null
  }
}
```

### **3. Obtener Imagen de Perfil**
```http
GET /users/profile-image/{filename}
```

**Ejemplo:**
```
GET /api/v1/users/profile-image/profile-123-1642598400000-abc123.jpg
```

**Respuesta:** Archivo de imagen binario con headers apropiados.

---

## 🛠️ **Implementación en Flutter**

### **1. Dependencias Necesarias**

Agrega estas dependencias a tu `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  image_picker: ^1.0.4
  path_provider: ^2.1.2
  cached_network_image: ^3.3.0
  flutter_cache_manager: ^3.3.1
```

### **2. Servicio de Imágenes de Perfil**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ProfileImageService {
  final String baseUrl;
  final String token;

  ProfileImageService({
    required this.baseUrl,
    required this.token,
  });

  /// Subir imagen de perfil
  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl/users/profile-image');

      // Crear multipart request
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          http.MultipartFile.fromBytes(
            'profileImage',
            await imageFile.readAsBytes(),
            filename: imageFile.path.split('/').last,
            contentType: MediaType.parse(
              lookupMimeType(imageFile.path) ?? 'image/jpeg'
            ),
          ),
        );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        throw Exception('Error al subir imagen: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Eliminar imagen de perfil
  Future<Map<String, dynamic>> deleteProfileImage() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/profile-image'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al eliminar imagen: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener URL completa de imagen de perfil
  String getProfileImageUrl(String? filename) {
    if (filename == null || filename.isEmpty) {
      return ''; // Retornar URL de imagen por defecto
    }
    return '$baseUrl/users/profile-image/$filename';
  }
}
```

### **3. Widget de Imagen de Perfil**

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageWidget extends StatefulWidget {
  final String? profileImageFilename;
  final String baseUrl;
  final String token;
  final Function(String?) onImageUpdated;

  const ProfileImageWidget({
    Key? key,
    required this.profileImageFilename,
    required this.baseUrl,
    required this.token,
    required this.onImageUpdated,
  }) : super(key: key);

  @override
  _ProfileImageWidgetState createState() => _ProfileImageWidgetState();
}

class _ProfileImageWidgetState extends State<ProfileImageWidget> {
  final ImagePicker _picker = ImagePicker();
  final ProfileImageService _imageService = ProfileImageService(
    baseUrl: widget.baseUrl,
    token: widget.token,
  );

  bool _isLoading = false;

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        final response = await _imageService.uploadProfileImage(File(image.path));

        // Actualizar el estado del usuario
        widget.onImageUpdated(response['user']['profileImage']);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen actualizada exitosamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProfileImage() async {
    try {
      setState(() => _isLoading = true);

      await _imageService.deleteProfileImage();
      widget.onImageUpdated(null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen eliminada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            if (widget.profileImageFilename != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar imagen', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProfileImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[300],
          child: widget.profileImageFilename != null
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: _imageService.getProfileImageUrl(widget.profileImageFilename),
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.person, size: 60),
                  fit: BoxFit.cover,
                  width: 120,
                  height: 120,
                ),
              )
            : const Icon(Icons.person, size: 60, color: Colors.grey),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: FloatingActionButton.small(
            onPressed: _showImageSourceDialog,
            child: const Icon(Icons.camera_alt),
          ),
        ),
      ],
    );
  }
}
```

### **4. Modelo de Usuario Actualizado**

```dart
class User {
  final int id;
  final String name;
  final String surname;
  final String email;
  final String? profileImage; // Nuevo campo

  User({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      surname: json['surname'],
      email: json['email'],
      profileImage: json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'email': email,
      'profileImage': profileImage,
    };
  }
}
```

### **5. Ejemplo de Uso en Pantalla de Perfil**

```dart
class ProfileScreen extends StatefulWidget {
  final User user;
  final String token;

  const ProfileScreen({
    Key? key,
    required this.user,
    required this.token,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  void _onProfileImageUpdated(String? newImageFilename) {
    setState(() {
      _currentUser = User(
        id: _currentUser.id,
        name: _currentUser.name,
        surname: _currentUser.surname,
        email: _currentUser.email,
        profileImage: newImageFilename,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProfileImageWidget(
              profileImageFilename: _currentUser.profileImage,
              baseUrl: 'http://tu-servidor:3000/api/v1',
              token: widget.token,
              onImageUpdated: _onProfileImageUpdated,
            ),
            const SizedBox(height: 20),
            Text('${_currentUser.name} ${_currentUser.surname}'),
            Text(_currentUser.email),
          ],
        ),
      ),
    );
  }
}
```

---

## ⚠️ **Consideraciones Importantes**

### **1. Manejo de Errores**
```dart
try {
  final response = await uploadProfileImage(imageFile);
  // Éxito
} catch (e) {
  if (e.toString().contains('400')) {
    // Error de validación (tipo/tamaño de archivo)
  } else if (e.toString().contains('401')) {
    // Token expirado - redirigir a login
  } else {
    // Error de conexión
  }
}
```

### **2. Optimización de Imágenes**
- ✅ **Redimensionar** antes de subir (800x800px máximo recomendado)
- ✅ **Comprimir** calidad (85% recomendado)
- ✅ **Formato** preferido: JPEG para fotos, PNG para gráficos

### **3. Cache de Imágenes**
```dart
// Usar CachedNetworkImage para mejor performance
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.person),
  fit: BoxFit.cover,
)
```

### **4. Permisos en Android/iOS**
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

```xml
<!-- iOS Info.plist -->
<key>NSCameraUsageDescription</key>
<string>Para tomar fotos de perfil</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Para seleccionar fotos de perfil</string>
```

### **5. Validaciones del Frontend**
- ✅ **Tamaño máximo**: 5MB
- ✅ **Formatos**: jpeg, jpg, png, gif, webp
- ✅ **Dimensiones**: Recomendado 800x800px máximo

---

## 🔧 **Configuración del Backend**

### **Variables de Entorno**
```env
# No se requieren variables adicionales para imágenes de perfil
# El sistema usa el directorio uploads/profiles/ automáticamente
```

### **Permisos del Servidor**
Asegurarse de que el servidor tenga permisos de escritura en:
```
uploads/
└── profiles/
```

---

## 📊 **Códigos de Error**

| Código | Descripción |
|--------|-------------|
| 200 | Éxito |
| 400 | Archivo inválido / Tamaño excedido |
| 401 | Token inválido / No autorizado |
| 404 | Usuario no encontrado |
| 413 | Archivo demasiado grande |
| 500 | Error interno del servidor |

---

## 🎯 **Mejores Prácticas**

1. **Mostrar preview** antes de subir
2. **Comprimir imágenes** en el dispositivo
3. **Usar cache** para mejor performance
4. **Manejar estados de carga** apropiadamente
5. **Validar permisos** antes de acceder a cámara/galería
6. **Fallback a imagen por defecto** cuando no hay imagen de perfil

---

*Documentación creada: Enero 2026*
*API Version: 1.0*
*Sistema: Imágenes de Perfil - ManejApp*