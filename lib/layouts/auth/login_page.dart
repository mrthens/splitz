import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:splitz/layouts/auth/create_account.dart';
import 'package:splitz/layouts/dash/dashboard.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn =GoogleSignIn();
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  bool isLoading = false;

  Future<void> SignInWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;

      // Create a new credential using the Google access token and ID token
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      //sign in to firebase with google
      final UserCredential userCredential =
          await auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        //store data containers
        final String email = user.email ?? '';
        final String username = user.displayName ?? 'User';

        //storing data to Firestore
        final userRef = firebaseFirestore.collection('users').doc(user.uid);

        await userRef.set({
          'email': email,
          'username': username,
          'createdAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Logged In with Google")));
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Dashboard()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed : $e")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void forgotpassword() async{
      final email=_emailController.text.trim();
      if(email.isEmpty){
         ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter your email to reset password!")),
      );
      return;
      }
      setState(() {
        isLoading = true;
      });

      try{
        await auth.sendPasswordResetEmail(email: email);
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password reset link sent to your email!")),
      );
      }catch(e){
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("failed to send reset link: $e")),
      );
      }finally{
        setState(() {
          isLoading=false;
        });
      }
    
    }

  void login() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    setState(() {
      isLoading = true; // Start loading
    });

    try {
      if (email.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Enter your EmailAddress !")));
      } else if (pass.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Enter your Password !")));
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: pass);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Dashboard()));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("LoggedIn")));
        print("navigated");
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid credentials1")));
            break;
          case 'user-not-found':
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid credentials2")));
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid credentials3")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("failed")));
      }
    } finally {
      setState(() {
        isLoading = false; 
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Container(
              margin: EdgeInsets.only(top: 70),
              padding: EdgeInsets.fromLTRB(30, 50, 30, 30), // Add top padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: "Welcome back! glad to see you,",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(
                                text: ' again',
                                style: TextStyle(color: Colors.blue.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 60),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.blue.shade600,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.blue.shade600,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: forgotpassword,
                      child: Text(
                        "forgot password?",
                        
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 60),
                  ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Align(
                    child: Text(
                      "Or",
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: SignInWithGoogle,
                    icon: Icon(
                      Icons.login,
                      color: Colors.black,
                    ),
                    label: Text(
                      "Login with Google",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(color: Colors.blue.shade600),
                      ),
                    ),
                  ),
                  SizedBox(height: 100),
                  Align(
                    alignment: Alignment.center,
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: "Create account",
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                            ..onTap = (){
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>CreateAccount()));
                            }
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: SizedBox(
                    width:50 ,
                    height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


