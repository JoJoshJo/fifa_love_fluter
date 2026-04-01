import 'package:flutter/material.dart';
import 'package:fifalove_mobile/core/constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/me_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import 'edit_profile_screen.dart';
import '../../../core/supabase/supabase_config.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Sign Out', style: GoogleFonts.spaceGrotesk(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodySmall?.color))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Sign Out', style: GoogleFonts.inter(color: const Color(0xFFE83535)))),
        ],
      ),
    );

    if (confirmed == true) {
      await _repo.signOut();
    }
  }

  Future<void> _deleteAccount() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Delete Account', style: GoogleFonts.spaceGrotesk(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This action is permanent. Type DELETE to confirm.', style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyMedium?.color)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'DELETE',
                hintStyle: GoogleFonts.inter(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3)),
                fillColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodySmall?.color))),
          TextButton(onPressed: () {
            if (controller.text.trim() == 'DELETE') Navigator.pop(context, true);
          }, child: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFE83535)))),
        ],
      ),
    );

    if (confirmed == true) {
      await _repo.deleteAccount(_userId);
    }
  }

  void _showLanguageSheet() {
    final currentLang = _profile['app_language'] as String? ?? 'English';
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('LANGUAGE', style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, letterSpacing: 2)),
            const SizedBox(height: 16),
            ...['English', 'Spanish', 'Portuguese', 'French', 'Arabic', 'Japanese'].map((lang) {
              final isSelected = lang == currentLang;
              return ListTile(
                title: Text(lang, style: GoogleFonts.inter(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor) : null,
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
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
      );
    }

    final safeArea = MediaQuery.of(context).padding;
    final completion = _repo.calculateCompletion(_profile);
    final score = completion['score'] as int;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: safeArea.top + 32),

            // SECTION 1: PROFILE
            _buildProfileHeader(score),

            const SizedBox(height: 32),

            // SECTION 2: ACTION
            _buildActionSection(),

            const SizedBox(height: 48),

            // SECTION 3: SETTINGS & ACCOUNT
            _buildSettingsSection(isDark),

            const SizedBox(height: 40),
            TextButton(
              onPressed: _deleteAccount,
              child: Text('Delete Account', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFE83535).withValues(alpha: 0.4))),
            ),

            SizedBox(height: safeArea.bottom + 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(int score) {
    return Column(
      children: [
        // Avatar
        CircleAvatar(
          radius: 60,
          backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          backgroundImage: _profile['avatar_url'] != null ? NetworkImage(_profile['avatar_url']) : null,
          child: _profile['avatar_url'] == null ? const Icon(Icons.person, size: 60, color: Colors.white24) : null,
        ),
        const SizedBox(height: 16),

        // Name & Verified Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_profile['name'] ?? 'User', 
              style: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
            const SizedBox(width: 8),
            const Icon(Icons.verified, size: 18, color: FifaColors.emeraldSpring),
          ],
        ),
        const SizedBox(height: 6),

        // Nationality & Team
        Text('${_profile['nationality'] ?? 'Nationality'} · ${_profile['team_supported'] ?? 'Team Member'}', 
          style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color)),

        const SizedBox(height: 24),

        // Profile Strength Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Profile strength', style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5))),
                  Text('$score%', style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.bold, color: FifaColors.emeraldSpring)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 4,
                  backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                  color: FifaColors.emeraldSpring,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: GestureDetector(
        onTap: () async {
          final updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(initialProfile: _profile)));
          if (updated == true) _loadProfile();
        },
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text('Edit Profile', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(bool isDark) {
    return Column(
      children: [
        _buildSettingTile(
          icon: Icons.language_outlined,
          title: 'Language',
          trailing: Text(_profile['app_language'] ?? 'English', style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).primaryColor)),
          onTap: _showLanguageSheet,
        ),
        _buildSettingTile(
          icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          title: isDark ? 'Light Mode' : 'Dark Mode',
          trailing: Switch(
            value: isDark,
            activeThumbColor: FifaColors.emeraldSpring,
            onChanged: (v) => ref.read(themeProvider.notifier).toggleTheme(),
          ),
        ),
        _buildSettingTile(
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          onTap: () {
            // Password reset logic already exists
            final email = SupabaseConfig.client.auth.currentUser?.email;
            if (email != null) {
              SupabaseConfig.client.auth.resetPasswordForEmail(email);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset email sent! ✅'), backgroundColor: FifaColors.emeraldForest));
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
        ),
        _buildSettingTile(
          icon: Icons.logout_rounded,
          title: 'Sign Out',
          titleColor: const Color(0xFFE83535),
          onTap: _signOut,
        ),
      ],
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, Widget? trailing, Color? titleColor, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 32),
      leading: Icon(icon, size: 22, color: titleColor ?? Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
      title: Text(title, style: GoogleFonts.inter(fontSize: 15, color: titleColor ?? Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w500)),
      trailing: trailing ?? (onTap != null ? Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).dividerColor) : null),
    );
  }
}
