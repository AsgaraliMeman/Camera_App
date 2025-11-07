import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:camera_app/db_helper.dart';

class Image_Screen extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const Image_Screen({
    Key? key,
    required this.imagePaths,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<Image_Screen> createState() => _Image_ScreenState();
}

class _Image_ScreenState extends State<Image_Screen> {
  late PageController _pageController;
  late int _currentIndex;
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _filterDeletedImages();
  }

  // Exclude images that exist in the Recently Deleted list
  Future<void> _filterDeletedImages() async {
    try {
      List<Map<String, dynamic>> deletedImages = await dbHelper.getRecentlyDeleted();
      List<String> deletedImagePaths = deletedImages.map((image) => image['imagePath'] as String).toList();

      setState(() {
        widget.imagePaths.removeWhere((path) => deletedImagePaths.contains(path));
      });
    } catch (e) {
      debugPrint("Error filtering deleted images: $e");
    }
  }

  void _deleteImage(BuildContext context) async {
    bool confirmDelete = await _showDeleteDialog(context);
    if (confirmDelete) {
      String currentImagePath = widget.imagePaths[_currentIndex];

      if (File(currentImagePath).existsSync()) {
        await dbHelper.addToRecentlyDeleted(currentImagePath);
        _filterDeletedImages(); // Update UI after deletion

        if (widget.imagePaths.isEmpty) {
          Navigator.pop(context, true);
        }

        // Notify the Home Screen to refresh images
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image moved to Recently Deleted"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: File not found!"), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _shareImage() {
    final file = XFile(widget.imagePaths[_currentIndex]);
    Share.shareXFiles([file], text: "Check out this photo!");
  }

  Future<bool> _showDeleteDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text("Are you sure you want to delete this image?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imagePaths.isEmpty) {
      return Scaffold(
        appBar: AppBar(backgroundColor: const Color.fromARGB(255, 10, 186, 250)),
        body: const Center(child: Text("No images left")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 10, 186, 250),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imagePaths.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(8.0),
                  minScale: 1.0,
                  maxScale: 5.0,
                  child: Image.file(File(widget.imagePaths[index]), fit: BoxFit.contain),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _shareImage,
                icon: const Icon(Icons.share),
                label: const Text("Share"),
              ),
              ElevatedButton.icon(
                onPressed: () => _deleteImage(context),
                icon: const Icon(Icons.delete),
                label: const Text("Delete"),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
