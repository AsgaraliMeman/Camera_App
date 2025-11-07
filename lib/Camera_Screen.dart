import 'package:camera_app/Image_Screen.dart';
import 'package:camera_app/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class MyCameraScreen extends StatefulWidget {
  const MyCameraScreen({super.key});

  @override
  State<MyCameraScreen> createState() => _MyCameraScreenState();
}

class _MyCameraScreenState extends State<MyCameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  DatabaseHelper dbHelper = DatabaseHelper();

  List<String> imagePaths = [];
  int lastImageIndex = 0;

  bool _flashEffect = false;
  bool _isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadImages();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    CameraDescription selectedCamera = _isFrontCamera
        ? cameras!.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front)
        : cameras![0];

    _cameraController = CameraController(selectedCamera, ResolutionPreset.high);
    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadImages() async {
    try {
      List<Map<String, dynamic>> images = await dbHelper.getImages();
      List<Map<String, dynamic>> deletedImages = await dbHelper.getRecentlyDeleted();

      // Extract deleted image paths
      List<String> deletedImagePaths = deletedImages.map((image) => image['imagePath'] as String).toList();

      setState(() {
        // Remove images that exist in the Recently Deleted list
        imagePaths = images.map((image) => image['imagePath'] as String)
            .where((path) => !deletedImagePaths.contains(path))
            .toList();
        lastImageIndex = imagePaths.isNotEmpty ? imagePaths.length - 1 : 0;
      });
    } catch (e) {
      debugPrint("Error loading images: $e");
    }
  }

  void _switchToFrontCamera() {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _initializeCamera();
    });
  }

  void _triggerFlashEffect() {
    setState(() {
      _flashEffect = true;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _flashEffect = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _cameraController == null || !_cameraController!.value.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : CameraPreview(_cameraController!),
          if (_flashEffect) Container(color: Colors.white.withOpacity(0.8)),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Thumbnail preview (updated to exclude deleted images)
            SizedBox(
              width: 60,
              height: 60,
              child: imagePaths.isNotEmpty
                  ? GestureDetector(
                      onTap: () async {
                        bool? deleted = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Image_Screen(
                              imagePaths: List.from(imagePaths),
                              initialIndex: lastImageIndex,
                            ),
                          ),
                        );
                        if (deleted == true) {
                          await _loadImages();
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(imagePaths[lastImageIndex]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
            ),

            // Center: Capture button
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white24,
              ),
              child: IconButton(
                onPressed: () async {
                  if (_cameraController != null) {
                    _triggerFlashEffect();
                    XFile image = await _cameraController!.takePicture();
                    await dbHelper.insertImage(image.path);
                    await _loadImages();
                  }
                },
                icon: const Icon(Icons.photo_camera_outlined),
                iconSize: 30,
                color: Colors.white,
              ),
            ),

            // Right: Flip camera button
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white24,
              ),
              child: IconButton(
                onPressed: _switchToFrontCamera,
                icon: const Icon(Icons.switch_camera),
                iconSize: 30,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
