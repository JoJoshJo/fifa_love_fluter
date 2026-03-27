import 'package:flutter/material.dart';
import '../supabase/supabase_config.dart';
import '../../features/auth/presentation/landing_screen.dart';
import '../../features/auth/presentation/setup_screen.dart';
import '../../shared/presentation/main_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: SupabaseConfig.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final session = snapshot.data!.session;

          if (session != null) {
            // User is logged in
            // Check if profile is complete
            return FutureBuilder(
              future: SupabaseConfig.client
                  .from('profiles')
                  .select('nationality')
                  .eq('id', session.user.id)
                  .single(),
              builder: (context, profileSnapshot) {
                // Fallback catch if the DB doesn't exist yet!
                if (profileSnapshot.hasError) {
                  return const SetupScreen();
                }
                
                if (profileSnapshot.hasData) {
                  final nationality = profileSnapshot.data?['nationality'];
                  if (nationality == null) {
                    return const SetupScreen();
                  }
                  return const MainScreen();
                }
                // Loading
                return _loadingScreen();
              },
            );
          }
        }
        // Not logged in
        return const LandingScreen();
      },
    );
  }

  Widget _loadingScreen() {
    return const Scaffold(
      backgroundColor: Color(0xFF080F0C),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4CB572),
          strokeWidth: 2,
        ),
      ),
    );
  }
}
