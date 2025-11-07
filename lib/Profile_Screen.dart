import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required User user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _nameController.text = _user!.displayName ?? ""; // Get username from FirebaseAuth
      _emailController.text = _user!.email ?? ""; // Get email from FirebaseAuth
    }
  }

  Future<void> updateInfo() async {
    if (_user == null) return;
    try {
      await _user!.updateDisplayName(_nameController.text.trim());
      await _user!.reload(); // Refresh user instance

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Profile updated successfully!!", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue[300],
        ),
      );

      setState(() {
        _user = FirebaseAuth.instance.currentUser; // Reload user info
      });
    } catch (e) {
      debugPrint("Error updating profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Colors.blue[300],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 70,
              backgroundImage: _user?.photoURL != null
                  ? NetworkImage(_user!.photoURL!) // Use Google profile image if available
                  : AssetImage("assets/default_avatar.png") as ImageProvider, // Show default avatar if no image
            ),
            SizedBox(height: 40),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Enter Name",
                labelText: "Username",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.person, color: Colors.black),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _emailController,
              enabled: false, // Email should not be editable
              decoration: InputDecoration(
                hintText: "Enter Email",
                labelText: "Email",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.email, color: Colors.black),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(horizontal: 160, vertical: 15),
              ),
              onPressed: updateInfo,
              child: Text("Update", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
