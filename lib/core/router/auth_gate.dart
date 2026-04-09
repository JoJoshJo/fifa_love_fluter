import 'package:flutter/material.dart';
import '../supabase/supabase_config.dart';
import '../../features/auth/presentation/landing_screen.dart';
import '../../features/auth/presentation/setup_screen.dart';
import '../../shared/presentation/main_screen.dart';
import '../widgets/particle_background.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  /// Returns true if the user's profile has enough data to skip setup.
  /// Checks the DB profile first, then falls back to auth metadata.
  bool _isProfileComplete(
    Map<String, dynamic>? dbProfile,
    Map<String, dynamic>? metadata,
  ) {
    // Check DB profile for nationality (the primary completeness signal)
    final dbNationality = dbProfile?['nationality'] as String?;
    if (dbNationality != null && dbNationality.isNotEmpty) return true;

    // Fallback: check user_metadata (always written even for unconfirmed users)
    final metaNationality = metadata?['nationality'] as String?;
    if (metaNationality != null && metaNationality.isNotEmpty) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: SupabaseConfig.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        Widget child;

        if (snapshot.hasData) {
          final session = snapshot.data!.session;

          if (session != null) {
            final metadata = session.user.userMetadata;

            child = FutureBuilder(
              future: SupabaseConfig.client
                  .from('profiles')
                  .select('id, nationality, name, team_supported')
                  .eq('id', session.user.id)
                  .maybeSingle(),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return _loadingScreen();
                }

                final dbProfile = profileSnapshot.data as Map<String, dynamic>?;

                if (!_isProfileComplete(dbProfile, metadata)) {
                  return const SetupScreen(key: ValueKey('setup'));
                }

                // If the DB profile is incomplete but metadata has data,
                // attempt a silent repair upsert so it won't re-prompt next time.
                if (dbProfile != null &&
                    (dbProfile['nationality'] == null) &&
                    (metadata?['nationality'] != null)) {
                  _repairProfileFromMetadata(session.user.id, metadata!);
                }

                return const MainScreen(key: ValueKey('main'));
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

  /// Fire-and-forget: write metadata fields into the profiles table.
  /// Called when the DB row is stale but metadata has good data (post-confirmation fix).
  Future<void> _repairProfileFromMetadata(
    String userId,
    Map<String, dynamic> metadata,
  ) async {
    try {
      await SupabaseConfig.client.from('profiles').upsert({
        'id': userId,
        'name': metadata['name'] ?? 'New Fan',
        'age': metadata['age'],
        'gender': metadata['gender'],
        'nationality': metadata['nationality'],
        'team_supported': metadata['team_supported'],
        'is_local': metadata['is_local'] ?? false,
        'city': metadata['city'],
        'match_type_preference': metadata['match_type_preference'] ?? [],
        'countries_to_match': metadata['countries_to_match'] ?? [],
      });
      debugPrint('[AUTH_GATE] Profile repaired from metadata.');
    } catch (e) {
      debugPrint('[AUTH_GATE] Profile repair failed: $e');
    }
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
