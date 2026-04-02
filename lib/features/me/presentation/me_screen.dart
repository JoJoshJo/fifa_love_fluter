import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../data/me_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import 'edit_profile_screen.dart';
import '../../../core/supabase/supabase_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:page_transition/page_transition.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';


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
    final isLight = Theme.of(context).brightness == Brightness.light;

    final bg = isLight
      ? const Color(0xFFF5F0E8)
      : const Color(0xFF080F0C);
    final card = isLight
      ? Colors.white
      : const Color(0xFF0D1A13);
    final border = isLight
      ? const Color(0xFFE8DDD0)
      : const Color(0xFF1E4A33);
    final text = isLight
      ? const Color(0xFF0D2B1E)
      : const Color(0xFFEBF2EE);
    final muted = isLight
      ? const Color(0xFF9BB3AF)
      : const Color(0xFF9BB3AF);
    const accent = Color(0xFF135E4B);
    const accentGreen = Color(0xFF4CB572);

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(
          child: CircularProgressIndicator(
            color: accentGreen,
            strokeWidth: 2,
          )),
      );
    }

    final safeArea = MediaQuery.of(context).padding;
    final completion =
      _repo.calculateCompletion(_profile);
    final score = completion['score'] as int;
    final missing =
      completion['missing'] as List;
    final avatarUrl =
      _profile['avatar_url'] as String?;
    final name =
      _profile['name'] as String? ?? 'Your Name';
    final isVerified =
      _profile['is_verified'] as bool? ?? false;
    final currentLang =
      _profile['app_language'] as String?
        ?? 'English';
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [

            // ── TOP HEADER BAR ─────────────────
            Container(
              padding: EdgeInsets.only(
                top: safeArea.top + 16,
                left: 24, right: 24,
                bottom: 0),
              color: bg,
              child: Row(
                children: [
                  Text(
                    'MY PROFILE',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      color: accentGreen,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      final updated =
                        await Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType
                              .bottomToTop,
                            duration: const Duration(
                              milliseconds: 320),
                            curve:
                              Curves.easeOutCubic,
                            child: EditProfileScreen(
                              initialProfile:
                                _profile),
                          ),
                        );
                      if (updated == true) {
                        _loadProfile();
                      }
                    },
                    child: Container(
                      padding:
                        const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius:
                          BorderRadius.circular(20),
                        border: isLight ? Border.all(
                          color: border) : null,
                        color: card,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.edit3,
                            size: 13,
                            color: accent),
                          const SizedBox(width: 5),
                          Text('Edit',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight:
                                FontWeight.w500,
                              color: accent)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── PROFILE PHOTO ──────────────────
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isLight ? Border.all(
                        color: isVerified
                          ? accentGreen
                          : border,
                        width: 2.5) : null,
                      color: isLight
                        ? const Color(0xFFE8F5EE)
                        : const Color(0xFF152B1E),
                    ),
                    child: ClipOval(
                      child: avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              name[0].toUpperCase(),
                              style: GoogleFonts
                                .playfairDisplay(
                                  fontSize: 44,
                                  fontWeight:
                                    FontWeight.w700,
                                  color: accentGreen,
                                )),
                          ),
                    ),
                  ),

                  // Camera button
                  Positioned(
                    bottom: 2, right: 2,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                        border: Border.all(
                          color: bg, width: 2)),
                      child: const Icon(
                        LucideIcons.camera,
                        size: 15,
                        color: Colors.white),
                    ),
                  ),

                  // Verified badge
                  if (isVerified)
                    Positioned(
                      top: 2, right: -4,
                      child: Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentGreen,
                          border: Border.all(
                            color: bg, width: 2)),
                        child: const Icon(
                          LucideIcons.checkCircle2,
                          size: 14,
                          color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── NAME ───────────────────────────
            Text(name,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: text,
                height: 1.1,
              )),

            const SizedBox(height: 6),
            
            // ── NATIONALITY + TEAM ─────────────
            Builder(
              builder: (context) {
                final nationality = _profile['nationality'] as String? ?? '';
                final team = _profile['team_supported'] as String? ?? '';
                if (nationality.isEmpty) return const SizedBox.shrink();
                return Text(
                  [
                    '${_flag(nationality)} $nationality',
                    if (team.isNotEmpty) team,
                  ].join('  ·  '),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: muted,
                  ));
              },
            ),

            const SizedBox(height: 20),

            // ── PROFILE STRENGTH ───────────────
            Padding(
              padding: const EdgeInsets
                .symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius:
                    BorderRadius.circular(16),
                  border: isLight ? Border.all(color: border) : null,
                  boxShadow: isLight ? [
                    BoxShadow(
                      color: Colors.black
                        .withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('PROFILE STRENGTH',
                          style: GoogleFonts
                            .spaceMono(
                              fontSize: 9,
                              color: accentGreen,
                              letterSpacing: 1.5,
                            )),
                        const Spacer(),
                        Text('$score%',
                          style: GoogleFonts
                            .playfairDisplay(
                              fontSize: 20,
                              fontWeight:
                                FontWeight.w700,
                              color: score < 50
                                ? const Color(
                                    0xFFE83535)
                                : score < 80
                                  ? const Color(
                                      0xFFF2C233)
                                  : accentGreen,
                            )),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius:
                        BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: score / 100,
                        minHeight: 5,
                        backgroundColor: isLight
                          ? const Color(0xFFF0EBE3)
                          : Colors.white
                            .withValues(alpha: 0.08),
                        valueColor:
                          AlwaysStoppedAnimation(
                            score < 50
                              ? const Color(
                                  0xFFE83535)
                              : score < 80
                                ? const Color(
                                    0xFFF2C233)
                                : accentGreen),
                      ),
                    ),
                    if (missing.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...missing.take(2).map((tip) =>
                        Padding(
                          padding: const EdgeInsets
                            .only(top: 5),
                          child: Row(children: [
                            Icon(
                              LucideIcons.plusCircle,
                              size: 13,
                              color: const Color(
                                0xFFE83535)
                                .withValues(
                                  alpha: 0.6)),
                            const SizedBox(width: 6),
                            Text(tip as String,
                              style: GoogleFonts
                                .inter(
                                  fontSize: 12,
                                  color: muted)),
                          ]),
                        )),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── SETTINGS SECTION ───────────────
            _sectionLabel('SETTINGS',
              color: accentGreen),
            const SizedBox(height: 10),

            _settingsGroup(
              card: card,
              border: border,
              isLight: isLight,
              children: [
                _settingRow(
                  icon: LucideIcons.moon,
                  title: 'Dark Mode',
                  text: text,
                  iconColor: accent,
                  border: border,
                  trailing: Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: themeMode ==
                        ThemeMode.dark,
                      activeThumbColor: accentGreen,
                      activeTrackColor: accentGreen
                        .withValues(alpha: 0.3),
                      inactiveThumbColor: isLight
                        ? const Color(0xFF9BB3AF)
                        : Colors.white38,
                      inactiveTrackColor: isLight
                        ? const Color(0xFFE8DDD0)
                        : Colors.white12,
                      onChanged: (_) => ref.read(
                        themeProvider.notifier)
                        .toggleTheme(),
                    ),
                  ),
                ),
                _divider(border),
                _settingRow(
                  icon: LucideIcons.languages,
                  title: 'Language',
                  subtitle: currentLang,
                  text: text,
                  iconColor: accent,
                  border: border,
                  onTap: _showLanguageSheet,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── ACCOUNT SECTION ────────────────
            _sectionLabel('ACCOUNT',
              color: accentGreen),
            const SizedBox(height: 10),

            _settingsGroup(
              card: card,
              border: border,
              isLight: isLight,
              children: [
                _settingRow(
                  icon: LucideIcons.lock,
                  title: 'Change Password',
                  text: text,
                  iconColor: muted,
                  border: border,
                  onTap: () async {
                    final email = SupabaseConfig.client.auth.currentUser?.email;
                    if (email == null) return;
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await SupabaseConfig.client.auth.resetPasswordForEmail(email);
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('Reset email sent ✅'),
                          backgroundColor: accent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('Could not send email'),
                          backgroundColor: const Color(0xFFE83535),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                ),
                _divider(border),
                _settingRow(
                  icon: LucideIcons.logOut,
                  title: 'Sign Out',
                  text: const Color(0xFFE83535)
                    .withValues(alpha: 0.8),
                  iconColor: const Color(0xFFE83535)
                    .withValues(alpha: 0.8),
                  border: border,
                  onTap: _signOut,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Delete account
            TextButton(
              onPressed: _deleteAccount,
              child: Text(
                'Delete Account',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFFE83535)
                    .withValues(alpha: 0.35),
                )),
            ),

            // Footer
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment:
                MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text('Privacy',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: muted,
                    ),
                  ),
                ),
                Text('·',
                  style: TextStyle(
                    color: muted
                      .withValues(alpha: 0.4))),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsScreen()),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text('Terms',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: muted,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'FIFA LOVE · World Cup 2026',
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                color: muted
                  .withValues(alpha: 0.4))),

            SizedBox(
              height: safeArea.bottom + 100),
          ],
        ),
      ),
    );
  }

  // ── HELPER WIDGETS ─────────────────────

  Widget _sectionLabel(String label,
    {required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label,
          style: GoogleFonts.spaceMono(
            fontSize: 9,
            color: color,
            letterSpacing: 2,
          )),
      ),
    );
  }

  Widget _settingsGroup({
    required Color card,
    required Color border,
    required bool isLight,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: isLight ? Border.all(color: border) : null,
          boxShadow: isLight ? [
            BoxShadow(
              color: Colors.black
                .withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String title,
    required Color text,
    required Color iconColor,
    required Color border,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 16, vertical: 2),
      leading: Icon(icon,
        color: iconColor, size: 20),
      title: Text(title,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: text,
          fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
        ? Text(subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: text
                .withValues(alpha: 0.4)))
        : null,
      trailing: trailing ?? (onTap != null
        ? Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: text
              .withValues(alpha: 0.25))
        : null),
    );
  }

  Widget _divider(Color border) {
    return Divider(
      height: 1, thickness: 1,
      color: border,
      indent: 52);
  }

  String _flag(String? n) {
    const m = {
      'Brazil': '🇧🇷', 'France': '🇫🇷',
      'Argentina': '🇦🇷',
      'United States': '🇺🇸',
      'England': '🏴',
      'Germany': '🇩🇪', 'Spain': '🇪🇸',
      'Portugal': '🇵🇹', 'Morocco': '🇲🇦',
      'Japan': '🇯🇵', 'Nigeria': '🇳🇬',
      'Benin': '🇧🇯', 'Ghana': '🇬🇦',
    };
    return m[n] ?? '🌍';
  }
}
