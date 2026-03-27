import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF080F0C),
      body: Center(child: Text("Main Screen (Bottom Nav Shell)", style: TextStyle(color: Colors.white))),
    );
  }
}
