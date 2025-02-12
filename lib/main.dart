import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:splitz/layouts/auth/create_account.dart';
import 'package:splitz/layouts/auth/onBoarding.dart';
import 'package:splitz/layouts/dash/dashboard.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'layouts/auth/login_page.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

class OnlineStatusService with WidgetsBindingObserver {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  void updateOnlineStatus(bool isOnline) {
    if (auth.currentUser != null) {
      firestore.collection('users').doc(auth.currentUser!.uid).update({
        'online': isOnline,
        'lastSeen': isOnline
            ? FieldValue.serverTimestamp()
            : FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      updateOnlineStatus(false);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before running the app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
   // Initialize Firebase Messaging


  // Create OnlineStatusService instance after Firebase initialization
  OnlineStatusService onlineStatusService = OnlineStatusService();
  WidgetsBinding.instance.addObserver(onlineStatusService);

  runApp(MainApp());
}




class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthendicationWrapper(),
    );
  }
}

class AuthendicationWrapper extends StatelessWidget {
  const AuthendicationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Ensure the user document exists
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .then((docSnapshot) {
        if (!docSnapshot.exists) {
          FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'online': false,
            'lastSeen': FieldValue.serverTimestamp(),
          });
        }
      });

      return Dashboard();
    } else {
      return LoginPage();
    }
  }
}
