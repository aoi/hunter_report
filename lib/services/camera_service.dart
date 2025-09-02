import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static CameraController? _controller;
  static List<CameraDescription> _cameras = [];

  static CameraController? get controller => _controller;
  static List<CameraDescription> get cameras => _cameras;

  static Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras[0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  static Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<String?> takePicture() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        return null;
      }

      final XFile image = await _controller!.takePicture();
      return image.path;
    } catch (e) {
      print('Error taking picture: $e');
      return null;
    }
  }

  static Future<String?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return image.path;
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  static Future<String?> pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return image.path;
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  static Future<String> saveImageToAppDirectory(String imagePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'hunt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${appDir.path}/$fileName';
      
      final file = File(imagePath);
      await file.copy(savedPath);
      
      return savedPath;
    } catch (e) {
      print('Error saving image: $e');
      return imagePath;
    }
  }

  static Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
}

