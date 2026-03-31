import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/supabase/supabase_config.dart';
import '../data/me_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import 'edit_profile_screen.dart';

class MeScreen extends ConsumerStatefulWidget {
  const MeScreen({super.key});

  @override
  ConsumerState<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends ConsumerState<MeScreen> {
  final _repo = MeRepository();
  Map<String, dynamic> _profile = {};
  bool _loading = true;

  String get _userId => SupabaseConfig.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _repo.fetchProfile(_userId);
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1A13),
        title: Text('Sign Out', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white30))),
          TextButton(onPressed: () async {
            Navigator.pop(context);
            await _repo.signOut();
          }, child: Text('Sign Out', style: GoogleFonts.inter(color: const Color(0xFFE83535)))),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1A13),
        title: Text('Delete Account', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Type DELETE to confirm account deletion.', style: GoogleFonts.inter(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                fillColor: const Color(0xFF152B1E),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white30))),
          TextButton(onPressed: () async {
            if (controller.text.trim() == 'DELETE') {
              Navigator.pop(context);
              await _repo.deleteAccount(_userId);
            }
          }, child: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFE83535)))),
        ],
      ),
    );
  }

  void _showLanguageSheet() {
    final currentLang = _profile['app_language'] as String? ?? 'English';
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1A13),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SELECT LANGUAGE', style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4CB572), letterSpacing: 2)),
            const SizedBox(height: 16),
            ...['English', 'Spanish', 'Portuguese', 'French', 'Arabic', 'Japanese'].map((lang) {
              final isSelected = lang == currentLang;
              return ListTile(
                title: Text(lang, style: GoogleFonts.inter(color: isSelected ? const Color(0xFF4CB572) : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF4CB572)) : null,
                onTap: () async {
                  await _repo.updateProfile(_userId, {'app_language': lang});
                  setState(() => _profile['app_language'] = lang);
                  if (mounted) Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: Color(0xFF080F0C), body: Center(child: CircularProgressIndicator(color: Color(0xFF4CB572))));
    }

    final safeArea = MediaQuery.of(context).padding;
    final completion = _repo.calculateCompletion(_profile);
    final score = completion['score'] as int;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF080F0C),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: safeArea.top + 16),

            // Profile Header Section
            Center(
              child: Stack(
                children: [
                   CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF152B1E),
                    backgroundImage: _profile['avatar_url'] != null ? NetworkImage(_profile['avatar_url']) : null,
                    child: _profile['avatar_url'] == null ? const Icon(Icons.person, size: 50, color: Colors.white24) : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Color(0xFF4CB572), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(_profile['name'] ?? 'User', style: GoogleFonts.spaceGrotesk(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('🇧🇷 ${_profile['nationality'] ?? 'Nationality'} · ${_profile['team_supported'] ?? 'Team'}', 
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9BB3AF))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF4CB572).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, size: 14, color: Color(0xFF4CB572)),
                  const SizedBox(width: 4),
                  Text('Level 1 Fans', style: GoogleFonts.spaceMono(fontSize: 10, color: const Color(0xFF4CB572), fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Profile Strength
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Profile $score%', style: GoogleFonts.spaceMono(fontSize: 10, color: const Color(0xFF4CB572))),
                      const Spacer(),
                      Text('${3 - (completion['missing'] as List).length} missing steps', style: GoogleFonts.spaceMono(fontSize: 10, color: Colors.white.withValues(alpha: 0.3))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      minHeight: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      color: score < 50 ? const Color(0xFFE83535) : const Color(0xFF4CB572),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Edit Profile Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () async {
                  final updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(initialProfile: _profile)));
                  if (updated == true) _loadProfile();
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(colors: [Color(0xFF135E4B), Color(0xFF4CB572)]),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Edit Profile', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Settings Section
            _buildSectionHeader('SETTINGS'),
            const SizedBox(height: 8),
            _buildSettingItem(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              trailing: Switch(
                value: isDark,
                activeTrackColor: const Color(0xFF4CB572),
                onChanged: (v) => ref.read(themeProvider.notifier).toggleTheme(),
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingItem(
              icon: Icons.language,
              title: 'Language',
              subtitle: _profile['app_language'] ?? 'English',
              onTap: _showLanguageSheet,
            ),

            const SizedBox(height: 32),

            // Account Section
            _buildSectionHeader('ACCOUNT'),
            const SizedBox(height: 8),
            _buildSettingItem(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: () async {
                final email = SupabaseConfig.client.auth.currentUser?.email;
                if (email != null) {
                  await SupabaseConfig.client.auth.resetPasswordForEmail(email);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset email sent! ✅'), backgroundColor: Color(0xFF135E4B)));
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            _buildSettingItem(
              icon: Icons.logout,
              title: 'Sign Out',
              titleColor: const Color(0xFFE83535).withValues(alpha: 0.7),
              onTap: _signOut,
            ),

            const SizedBox(height: 24),
            TextButton(
              onPressed: _deleteAccount,
              child: Text('Delete Account', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFE83535).withValues(alpha: 0.35))),
            ),

            SizedBox(height: safeArea.bottom + 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: GoogleFonts.spaceMono(fontSize: 9, color: const Color(0xFF4CB572), letterSpacing: 2)),
      ),
    );
  }

  Widget _buildSettingItem({required IconData icon, required String title, String? subtitle, Widget? trailing, Color? titleColor, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF0D1A13), borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: titleColor ?? const Color(0xFF4CB572), size: 20),
          title: Text(title, style: GoogleFonts.inter(fontSize: 15, color: titleColor ?? Colors.white)),
          subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))) : null,
          trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: Colors.white12, size: 20) : null),
        ),
      ),
    );
  }
}
