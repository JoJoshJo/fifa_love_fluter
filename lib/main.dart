import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/landing_screen.dart';

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
      home: const LandingScreen(),
    );
  }
}
