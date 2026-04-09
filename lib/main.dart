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

  // Early Deep Link Check for Password Recovery or signup confirmation
  final uri = Uri.base;
  bool showResetScreen = false;
  
  // Debug logging for troubleshooting hash routes
  debugPrint('DEBUG: Current URL: ${uri.toString()}');
  debugPrint('DEBUG: Fragment: ${uri.fragment}');
  
  if (uri.fragment.contains('code=')) {
    try {
      // Use a dummy base URL to reliably parse the hash fragment as a path
      final fragment = uri.fragment.startsWith('/') ? uri.fragment : '/${uri.fragment}';
      final recoveryUri = Uri.parse('https://fifalove.app$fragment');
      
      final code = recoveryUri.queryParameters['code'];
      final type = recoveryUri.queryParameters['type'];

      if (code != null) {
        debugPrint('DEBUG: Exchanging code for session...');
        await Supabase.instance.client.auth.exchangeCodeForSession(code);
        debugPrint('DEBUG: Session exchange successful. Type: $type');
        
        if (type == 'recovery' || fragment.contains('reset-password')) {
          showResetScreen = true;
          debugPrint('DEBUG: Recovery flow detected. Setting showResetScreen = true');
        }
      }
    } catch (e) {
      debugPrint('[INIT_DEEP_LINK_ERROR] $e');
    }
  }
  
  runApp(ProviderScope(
    child: TurfAndArdorApp(showResetScreen: showResetScreen)
  ));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class TurfAndArdorApp extends ConsumerStatefulWidget {
  final bool showResetScreen;
  const TurfAndArdorApp({
    super.key,
    this.showResetScreen = false,
  });

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
      home: widget.showResetScreen 
          ? const ResetPasswordScreen() 
          : const SplashScreen(),
    );
  }
}
