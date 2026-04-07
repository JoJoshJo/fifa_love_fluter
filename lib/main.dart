import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/supabase/supabase_config.dart';
import 'core/router/auth_gate.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'core/notifications/notification_service.dart';

import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  await Future.wait([
    Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    ),
    NotificationService().initialize(),
  ]);
  
  runApp(const ProviderScope(child: TurfAndArdorApp()));
}

class TurfAndArdorApp extends ConsumerWidget {
  const TurfAndArdorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Turf&Ardor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
