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

  // Robust Deep Link Check for Password Recovery or signup confirmation
  final uri = Uri.base;
  bool isPasswordRecovery = false;
  bool isSignupConfirm = false;
  String? deepLinkError;
  
  // Debug logging for troubleshooting hash routes
  debugPrint('DEBUG: Current URL: ${uri.toString()}');
  debugPrint('DEBUG: Fragment: ${uri.fragment}');
  
  // 1. Check fragments (standard for Supabase redirects)
  if (uri.fragment.isNotEmpty) {
    if (uri.fragment.contains('type=recovery') || uri.fragment.contains('reset-password')) {
      isPasswordRecovery = true;
    } else if (uri.fragment.contains('type=signup') || uri.fragment.contains('confirm')) {
      isSignupConfirm = true;
    }

    if (isPasswordRecovery || isSignupConfirm) {
      try {
        final fragment = uri.fragment.startsWith('/') ? uri.fragment : '/${uri.fragment}';
        final recoveryUri = Uri.parse('https://placeholder.local$fragment');
        final code = recoveryUri.queryParameters['code'];
        
        if (code != null) {
          debugPrint('DEBUG: Exchanging code (fragment) for session...');
          await Supabase.instance.client.auth.exchangeCodeForSession(code);
          debugPrint('DEBUG: Fragment session exchange successful.');
          WebUtils.clearUrl();
        }
      } catch (e) {
        debugPrint('[DEEP_LINK_FRAGMENT_ERROR] $e');
        deepLinkError = 'This link has already been used or has expired. Please request a new one.';
      }
    }
  }

  // 2. Check non-fragment query params (Supabase sometimes uses ?code= directly)
  if (!isPasswordRecovery && !isSignupConfirm) {
    if (uri.queryParameters['type'] == 'recovery' || uri.path.contains('reset-password')) {
      isPasswordRecovery = true;
    } else if (uri.queryParameters['type'] == 'signup' || uri.path.contains('confirm')) {
      isSignupConfirm = true;
    }

    if (isPasswordRecovery || isSignupConfirm) {
      final code = uri.queryParameters['code'];
      if (code != null) {
        try {
          debugPrint('DEBUG: Exchanging code (query) for session...');
          await Supabase.instance.client.auth.exchangeCodeForSession(code);
          debugPrint('DEBUG: Query session exchange successful.');
          WebUtils.clearUrl();
        } catch (e) {
          debugPrint('[DEEP_LINK_QUERY_ERROR] $e');
          deepLinkError = 'This link has already been used or has expired. Please request a new one.';
        }
      }
    }
  }

  runApp(ProviderScope(
    child: TurfAndArdorApp(
      showPasswordReset: isPasswordRecovery,
      deepLinkError: deepLinkError,
    )
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
              backgroundColor: const Color(0xFFC62828),
              duration: const Duration(seconds: 5),
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
