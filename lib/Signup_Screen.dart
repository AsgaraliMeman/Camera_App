import 'package:camera_app/Home_Screen.dart';
import 'package:camera_app/Login_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class My_Signup_Screen extends StatefulWidget {
  const My_Signup_Screen({super.key});

  @override
  State<My_Signup_Screen> createState() => _My_Signup_ScreenState();
}

class _My_Signup_ScreenState extends State<My_Signup_Screen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoading = false;

  Future<void> registerUser(
      String? username, String? email, String? password, dynamic FirebaseFirestore) async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email!,
        password: password!,
      );

      User? user = userCredential.user;

      await FirebaseFirestore.instance.collection("User").doc(user?.uid).set({
        "Username": username,
        "email": email,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You are Signed Up!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Signup Failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google Sign-In Successful!"),
            backgroundColor: Color.fromARGB(255, 10, 186, 250),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyHomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google Sign-In Failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A90E2), 
            Color(0xFFD3D3D3),
            Color(0xFFA9A9A9),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "WELCOME",
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Let's create an account for you",
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(height: 30),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: "Username",
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? "Please enter a username" : null,
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? "Please enter your email" : null,
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter a password";
                            } else if (value.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 30),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      registerUser(
                                        _nameController.text.trim(),
                                        _emailController.text.trim(),
                                        _passwordController.text,
                                      );
                                    }
                                  },
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.blue)
                                : Text("Signup",style: TextStyle(color: Colors.black),),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[50],
                              
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MyLoginScreen()),
                            );
                          },
                          child: Text("Already have an account? Login"),
                        ),
                        SizedBox(height: 10),
                        Text("OR", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 20),
                        SizedBox(
                          width: 250,
                          child: OutlinedButton.icon(
                            icon: SizedBox(
                              width: 24,
                              height: 24,
                              child: Image.asset("assets/images/google.png"),
                            ),
                            label: Text(
                              "Signup with Google",
                              style: TextStyle(color: Colors.black),
                            ),
                            onPressed: signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[50],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
