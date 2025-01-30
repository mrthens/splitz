import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          "assets/images/onBoardingImage2.png", // Ensure this path matches your `pubspec.yaml`
          width: 200,
          height: 200,
          fit: BoxFit.cover, // Optional
        ),
      ),
    );
  }
}
