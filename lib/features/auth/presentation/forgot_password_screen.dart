import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF080F0C),
      body: Center(child: Text("Forgot Password Screen", style: TextStyle(color: Colors.white))),
    );
  }
}
