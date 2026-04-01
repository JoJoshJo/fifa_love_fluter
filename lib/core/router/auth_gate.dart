import 'package:flutter/material.dart';
import '../supabase/supabase_config.dart';
import '../../features/auth/presentation/landing_screen.dart';
import '../../features/auth/presentation/setup_screen.dart';
import '../../shared/presentation/main_screen.dart';
import '../widgets/particle_background.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: SupabaseConfig.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        Widget child;

        if (snapshot.hasData) {
          final session = snapshot.data!.session;

          if (session != null) {
            // User is logged in
            child = FutureBuilder(
              future: SupabaseConfig.client
                  .from('profiles')
                  .select('nationality')
                  .eq('id', session.user.id)
                  .single(),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.hasError) {
                  return const SetupScreen(key: ValueKey('setup'));
                }
                
                if (profileSnapshot.hasData) {
                  final nationality = profileSnapshot.data?['nationality'];
                  if (nationality == null) {
                    return const SetupScreen(key: ValueKey('setup'));
                  }
                  return const MainScreen(key: ValueKey('main'));
                }
                return _loadingScreen();
              },
            );
          } else {
            child = const LandingScreen(key: ValueKey('landing'));
          }
        } else {
          child = const LandingScreen(key: ValueKey('landing'));
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: child,
        );
      },
    );
  }

  Widget _loadingScreen() {
    return const Scaffold(
      backgroundColor: Color(0xFF080F0C),
      body: Stack(
        children: [
          Positioned.fill(child: ParticleBackground()),
          Center(
            child: CircularProgressIndicator(
              color: Color(0xFF4CB572),
              strokeWidth: 2,
            ),
          ),
        ],
      ),
    );
  }
}
