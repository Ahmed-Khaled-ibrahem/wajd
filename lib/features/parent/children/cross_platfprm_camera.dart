import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// Platform detection
class PlatformDetector {
  static bool get isRaspberryPi {
    if (!Platform.isLinux) return false;

    try {
      // Check for Raspberry Pi specific files
      final cpuInfo = File('/proc/cpuinfo');
      if (cpuInfo.existsSync()) {
        final content = cpuInfo.readAsStringSync();
        return content.contains('Raspberry Pi') ||
            content.contains('BCM2') ||
            content.contains('ARM');
      }
    } catch (e) {
      print('Error detecting Raspberry Pi: $e');
    }

    return false;
  }

  static bool get isAndroid => Platform.isAndroid;
  static bool get isLinux => Platform.isLinux;
}

// Cross-platform image picker
class CrossPlatformImagePicker {
  static final ImagePicker _imagePicker = ImagePicker();

  // Main method - automatically detects platform
  static Future<File?> pickImage(BuildContext context) async {
    if (PlatformDetector.isRaspberryPi) {
      return await _pickImageRaspberryPi(context);
    } else if (PlatformDetector.isAndroid) {
      return await _pickImageAndroid(context);
    } else {
      return await _pickImageDefault(context);
    }
  }

  // Android implementation (existing)
  static Future<File?> _pickImageAndroid(BuildContext context) async {
    final source = await _showImageSourceDialog(context);
    if (source == null) return null;

    final pickedImage = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (pickedImage != null) {
      return File(pickedImage.path);
    }

    return null;
  }

  // Raspberry Pi implementation (camera)
  static Future<File?> _pickImageRaspberryPi(BuildContext context) async {
    final method = await _showRaspberryPiMethodDialog(context);
    if (method == null) return null;

    switch (method) {
      case RaspberryPiCaptureMethod.camera:
        return await _captureWithCamera(context);
      case RaspberryPiCaptureMethod.libcamera:
        return await _captureWithLibcamera();
      case RaspberryPiCaptureMethod.filePicker:
        return await _pickFromFile(context);
    }
  }

  // Default implementation for other platforms
  static Future<File?> _pickImageDefault(BuildContext context) async {
    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (pickedImage != null) {
      return File(pickedImage.path);
    }

    return null;
  }

  // Method 1: Using camera package (Recommended for Raspberry Pi)
  static Future<File?> _captureWithCamera(BuildContext context) async {
    try {
      // Get available cameras
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No camera found on this device'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
        return null;
      }

      // Open camera screen
      if (context.mounted) {
        final imagePath = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => RaspberryPiCameraScreen(camera: cameras.first),
          ),
        );

        if (imagePath != null) {
          return File(imagePath);
        }
      }
    } catch (e) {
      print('Error accessing camera: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }

    return null;
  }

  // Method 2: Using libcamera command (Alternative for Raspberry Pi)
  static Future<File?> _captureWithLibcamera() async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = path.join(directory.path, 'capture_$timestamp.jpg');

      // Try libcamera-still first (Raspberry Pi OS Bullseye and later)
      ProcessResult result = await Process.run(
        'libcamera-still',
        [
          '-o', imagePath,
          '--width', '800',
          '--height', '600',
          '--timeout', '1000',
          '--nopreview',
        ],
      );

      // If libcamera-still not found, try raspistill (older systems)
      if (result.exitCode != 0) {
        result = await Process.run(
          'raspistill',
          [
            '-o', imagePath,
            '-w', '800',
            '-h', '600',
            '-t', '1000',
            '-n', // No preview
          ],
        );
      }

      if (result.exitCode == 0 && File(imagePath).existsSync()) {
        return File(imagePath);
      } else {
        print('Camera capture failed: ${result.stderr}');
        return null;
      }
    } catch (e) {
      print('Error capturing with libcamera: $e');
      return null;
    }
  }

  // Method 3: Pick from file system
  static Future<File?> _pickFromFile(BuildContext context) async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (pickedImage != null) {
        return File(pickedImage.path);
      }
    } catch (e) {
      print('Error picking file: $e');
    }

    return null;
  }

  // Android source dialog
  static Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.photo_library_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Choose Image Source'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF3B82F6)),
              ),
              title: const Text('Camera'),
              subtitle: const Text('Take a new photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF8B5CF6)),
              ),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  // Raspberry Pi method dialog
  static Future<RaspberryPiCaptureMethod?> _showRaspberryPiMethodDialog(
      BuildContext context,
      ) async {
    return await showDialog<RaspberryPiCaptureMethod>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.camera_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Capture Method'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF10B981)),
              ),
              title: const Text('Camera App'),
              subtitle: const Text('Use built-in camera (Recommended)'),
              onTap: () => Navigator.pop(context, RaspberryPiCaptureMethod.camera),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.center_focus_strong, color: Color(0xFF3B82F6)),
              ),
              title: const Text('Direct Capture'),
              subtitle: const Text('Quick capture with libcamera'),
              onTap: () => Navigator.pop(context, RaspberryPiCaptureMethod.libcamera),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder_rounded, color: Color(0xFF8B5CF6)),
              ),
              title: const Text('Choose File'),
              subtitle: const Text('Pick from file system'),
              onTap: () => Navigator.pop(context, RaspberryPiCaptureMethod.filePicker),
            ),
          ],
        ),
      ),
    );
  }
}

// Enum for Raspberry Pi capture methods
enum RaspberryPiCaptureMethod {
  camera,
  libcamera,
  filePicker,
}

// Camera screen for Raspberry Pi
class RaspberryPiCameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const RaspberryPiCameraScreen({super.key, required this.camera});

  @override
  State<RaspberryPiCameraScreen> createState() => _RaspberryPiCameraScreenState();
}

class _RaspberryPiCameraScreenState extends State<RaspberryPiCameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      if (mounted) {
        Navigator.pop(context, image.path);
      }
    } catch (e) {
      print('Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Camera preview
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller),
                  ),
                ),

                // Top bar
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        // Info
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Raspberry Pi Camera',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Capture button
                        GestureDetector(
                          onTap: _isCapturing ? null : _captureImage,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: _isCapturing
                                      ? null
                                      : const LinearGradient(
                                    colors: [
                                      Color(0xFF10B981),
                                      Color(0xFF059669),
                                    ],
                                  ),
                                  color: _isCapturing ? Colors.grey : null,
                                  shape: BoxShape.circle,
                                ),
                                child: _isCapturing
                                    ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                                    : const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Camera Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
              ),
            );
          }
        },
      ),
    );
  }
}