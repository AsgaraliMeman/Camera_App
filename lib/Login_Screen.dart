import 'package:camera_app/Home_Screen.dart';
import 'package:camera_app/Signup_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyLoginScreen extends StatefulWidget {
  const MyLoginScreen({super.key});

  @override
  State<MyLoginScreen> createState() => _MyLoginScreenState();
}

class _MyLoginScreenState extends State<MyLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginState(); 
  }

  Future<void> _checkLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn && _auth.currentUser != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MyHomeScreen()));
    }
  }

  Future<void> userLogin(String email, String password) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You are Signed In!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
      );

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MyHomeScreen()));
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _googleSignIn.signOut(); 

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; 

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In Successful!"), backgroundColor: Color.fromARGB(255, 10, 186, 250)),
      );

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MyHomeScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In Failed: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Login Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              _emailController.clear();
              _passwordController.clear();
              Navigator.of(context).pop();
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MyLoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A90E2), Color(0xFFD3D3D3), Color(0xFFA9A9A9)],
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
                          "Login with your email and password",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 30),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return "Please enter your email";
                            if (!value.contains("@")) return "Enter a valid email";
                            return null;
                          },
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
                            if (value == null || value.isEmpty) return "Please enter your password";
                            if (value.length < 6) return "Password must be at least 6 characters";
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
                                    userLogin(_emailController.text.trim(), _passwordController.text);
                                  },
                            child: _isLoading ? CircularProgressIndicator(color: Colors.blue) : Text("Login"),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => My_Signup_Screen()));
                          },
                          child: Text("Don't have an account? Sign Up"),
                        ),
                        SizedBox(height: 10),
                        Text("OR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(height: 20),
                        SizedBox(
                          width: 250,
                          child: OutlinedButton.icon(
                            icon: SizedBox(width: 24, height: 24, child: Image.asset("assets/images/google.png")),
                            label: Text("Continue with Google", style: TextStyle(color: Colors.black)),
                            onPressed: _isLoading ? null : signInWithGoogle,
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
