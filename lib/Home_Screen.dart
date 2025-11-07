import 'package:camera_app/Image_Screen.dart';
import 'package:camera_app/Login_Screen.dart';
import 'package:camera_app/Profile_Screen.dart';
import 'package:camera_app/Recently_Deleted.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:camera_app/db_helper.dart';
import 'package:camera_app/Camera_Screen.dart';

class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  List<String> imagePaths = [];
  DatabaseHelper dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      List<Map<String, dynamic>> images = await dbHelper.getImages();
      List<Map<String, dynamic>> deletedImages = await dbHelper.getRecentlyDeleted();

      // Extract deleted image paths
      List<String> deletedImagePaths = deletedImages.map((image) => image['imagePath'] as String).toList();

      if (mounted) {
        setState(() {
          // Filter out images moved to Recently Deleted
          imagePaths = images.map((image) => image['imagePath'] as String)
              .where((path) => !deletedImagePaths.contains(path))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading images: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home", style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 10, 186, 250),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => MyCameraScreen()));
              _loadImages();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              height: 93,
              width: double.infinity,
              color: const Color.fromARGB(255, 10, 186, 250),
              child: const Text("Camera", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const Divider(color: Color(0xFFA9A9A9), height: 3),
            ListTile(
              leading: const Icon(Icons.person, color: Color.fromARGB(255, 10, 186, 250)),
              title: const Text("Profile", style: TextStyle(color: Color.fromARGB(255, 10, 186, 250))),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(user: FirebaseAuth.instance.currentUser!)),
                );
              },
            ),
            const Divider(color: Color(0xFFA9A9A9), height: 3),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Color.fromARGB(255, 10, 186, 250)),
              title: const Text("Recently deleted", style: TextStyle(color: Color.fromARGB(255, 10, 186, 250))),
              onTap: () async {
                await dbHelper.deleteExpiredImages();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecentlyDeletedScreen(user: FirebaseAuth.instance.currentUser!)),
                );
              },
            ),
            const Divider(color: Color(0xFFA9A9A9), height: 3),
            ListTile(
              leading: const Icon(Icons.logout, color: Color.fromARGB(255, 10, 186, 250)),
              title: const Text("Log out", style: TextStyle(color: Color.fromARGB(255, 10, 186, 250))),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => MyLoginScreen()),
                  (route) => false,
                );
              },
            ),
            const Divider(color: Color(0xFFA9A9A9), height: 3),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text("Version 0.1.0", style: TextStyle(color: Colors.grey, fontSize: 18)),
            ),
          ],
        ),
      ),
      body: imagePaths.isEmpty
          ? _buildEmptyState()
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                ),
                itemCount: imagePaths.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      bool? deleted = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Image_Screen(
                            imagePaths: List.from(imagePaths),
                            initialIndex: index,
                          ),
                        ),
                      );
                      if (deleted == true) _loadImages();
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(imagePaths[index]), fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text("No images available", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
