import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:developer' as developer;

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      developer.log('Error picking image: $e', name: 'ImageService');
      return null;
    }
  }

  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      developer.log('Error taking photo: $e', name: 'ImageService');
      return null;
    }
  }

  static Future<File?> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      developer.log('Error picking document: $e', name: 'ImageService');
      return null;
    }
  }

  static Future<String?> uploadImage(File file, String type) async {
    try {
      // Aquí implementarías la lógica para subir la imagen a tu servidor
      // Por ahora retornamos una URL de ejemplo
      developer.log('Uploading image: ${file.path}', name: 'ImageService');

      // Simular upload
      await Future.delayed(const Duration(seconds: 1));

      // En producción, aquí harías el upload real y retornarías la URL
      return 'https://example.com/uploads/${DateTime.now().millisecondsSinceEpoch}.jpg';
    } catch (e) {
      developer.log('Error uploading image: $e', name: 'ImageService');
      return null;
    }
  }
}
