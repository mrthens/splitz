import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:splitz/layouts/create_account.dart';
import 'package:splitz/layouts/onBoarding.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'layouts/login_page.dart';


void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
  runApp( MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CreateAccount()
    );
  }
}
