import 'package:flutter/material.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF080F0C),
      body: Center(child: Text("Setup Screen (Nationality needed)", style: TextStyle(color: Colors.white))),
    );
  }
}
