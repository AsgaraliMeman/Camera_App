import 'dart:io';
import 'package:camera_app/db_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RecentlyDeletedScreen extends StatefulWidget {
  const RecentlyDeletedScreen({Key? key, required User user}) : super(key: key);

  @override
  State<RecentlyDeletedScreen> createState() => _RecentlyDeletedScreenState();
}

class _RecentlyDeletedScreenState extends State<RecentlyDeletedScreen> {
  List<Map<String, dynamic>> deletedImages = [];
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _cleanExpiredImages();
    _loadDeletedImages();
  }

  // Remove images older than 7 days and refresh the UI
  Future<void> _cleanExpiredImages() async {
    await dbHelper.deleteExpiredImages();
    _loadDeletedImages();
  }

  // Load recently deleted images from the database
  Future<void> _loadDeletedImages() async {
    try {
      List<Map<String, dynamic>> images = await dbHelper.getRecentlyDeleted();
      if (mounted) {
        setState(() {
          deletedImages = images;
        });
      }
    } catch (e) {
      debugPrint("Error loading recently deleted images: $e");
    }
  }

  // Restore image back to main gallery
  Future<void> _restoreImage(String imagePath) async {
    await dbHelper.restoreImage(imagePath);
    _loadDeletedImages();
  }

  // Permanently delete image after confirmation
  Future<void> _deleteImage(String imagePath) async {
    bool confirmDelete = await _showDeleteDialog();
    if (confirmDelete) {
      await dbHelper.deleteImagePermanently(imagePath);
      _loadDeletedImages();
    }
  }

  // Show a confirmation dialog before deleting
  Future<bool> _showDeleteDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Permanently"),
            content: const Text("This image will be deleted permanently. Are you sure?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text(
        "Recently Deleted", 
      style: TextStyle(
        color: Colors.white, 
        fontSize: 25, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 10, 186, 250),
        iconTheme: const IconThemeData(color: Colors.white),
        ),
      body: deletedImages.isEmpty
          ? const Center(child: Text("No recently deleted images", style: TextStyle(fontSize: 18)))
          : ListView.builder(
              itemCount: deletedImages.length,
              itemBuilder: (context, index) {
                final imagePath = deletedImages[index]['imagePath'];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Image.file(File(imagePath), fit: BoxFit.cover, height: 200),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () => _restoreImage(imagePath),
                            icon: const Icon(Icons.restore, color: Colors.green),
                            label: const Text("Restore"),
                          ),
                          TextButton.icon(
                            onPressed: () => _deleteImage(imagePath),
                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                            label: const Text("Delete"),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
