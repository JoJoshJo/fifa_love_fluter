import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/supabase/supabase_config.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/reset_password_screen.dart';
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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class TurfAndArdorApp extends ConsumerStatefulWidget {
  const TurfAndArdorApp({super.key});

  @override
  ConsumerState<TurfAndArdorApp> createState() => _TurfAndArdorAppState();
}

class _TurfAndArdorAppState extends ConsumerState<TurfAndArdorApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const ResetPasswordScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Turf&Ardor',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
