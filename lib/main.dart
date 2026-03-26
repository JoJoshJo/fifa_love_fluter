import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
// import 'core/router/app_router.dart'; // User's code includes this but we haven't created it yet. I'll include it exactly as the user requested.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FifaLoveApp());
}

class FifaLoveApp extends StatelessWidget {
  const FifaLoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FIFA Love',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const Scaffold(
        backgroundColor: Color(0xFF080F0C),
        body: Center(
          child: Text(
            'FIFA LOVE',
            style: TextStyle(
              color: Color(0xFFF2C233),
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
