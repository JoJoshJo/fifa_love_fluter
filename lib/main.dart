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
import 'core/utils/web_utils.dart';

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

  bool isPasswordRecovery = false;
  String? deepLinkError;
  
  // ONLY check for deep links if URL has actual parameters
  final uri = Uri.base;
  
  // Simple check: does the URL contain a code parameter?
  String? code;
  String? type;
  
  // Check fragment (hash route)
  if (uri.fragment.contains('code=')) {
    final fragmentUri = Uri.parse('https://x.com/${uri.fragment.startsWith('/') ? uri.fragment.substring(1) : uri.fragment}');
    code = fragmentUri.queryParameters['code'];
    type = fragmentUri.queryParameters['type'];
  }
  // Check query params
  else if (uri.queryParameters.containsKey('code')) {
    code = uri.queryParameters['code'];
    type = uri.queryParameters['type'];
  }
  
  // Only process if we actually have a code
  if (code != null && code.isNotEmpty) {
    try {
      await Supabase.instance.client.auth.exchangeCodeForSession(code);
      WebUtils.clearUrl();
      
      if (type == 'recovery') {
        isPasswordRecovery = true;
      }
    } catch (e) {
      // Don't show scary error — the confirmation likely already worked
      deepLinkError = 'Account confirmed! You can now sign in.';
      isPasswordRecovery = false;
    }
  }

  runApp(ProviderScope(
    child: TurfAndArdorApp(
      showPasswordReset: isPasswordRecovery,
      deepLinkError: deepLinkError,
    ),
  ));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class TurfAndArdorApp extends ConsumerStatefulWidget {
  final bool showPasswordReset;
  final String? deepLinkError;
  const TurfAndArdorApp({
    super.key,
    this.showPasswordReset = false,
    this.deepLinkError,
  });

  @override
  ConsumerState<TurfAndArdorApp> createState() => _TurfAndArdorAppState();
}

class _TurfAndArdorAppState extends ConsumerState<TurfAndArdorApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    // Handle runtime recovery events if the app is already open
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const ResetPasswordScreen(),
          ),
        );
      }
    });

    if (widget.deepLinkError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.deepLinkError!),
              backgroundColor: const Color(0xFF4CB572), // Green instead of red
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }
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
      // If we landed on a recovery link, skip splash and go straight to reset form
      home: widget.showPasswordReset 
          ? const ResetPasswordScreen() 
          : const SplashScreen(),
    );
  }
}
