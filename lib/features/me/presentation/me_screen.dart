import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/supabase/supabase_config.dart';
import '../data/me_repository.dart';
import 'widgets/profile_header.dart';
import 'widgets/completion_bar.dart';
import 'widgets/section_header.dart';
import 'widgets/field_tile.dart';
import 'widgets/interest_chip_grid.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  final _repo = MeRepository();
  Map<String, dynamic> _profile = {};
  bool _loading = true;
  bool _hasChanges = false;
  bool _saving = false;

  String _name = '';
  String _bio = '';
  String _nationality = '';
  String _teamSupported = '';
  String _city = '';
  bool _isLocal = false;
  List<String> _interests = [];
  List<String> _languages = [];
  List<String> _matchTypes = [];

  String get _userId =>
      SupabaseConfig.client.auth.currentUser?.id ?? '';

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
        _name = profile['name'] as String? ?? '';
        _bio = profile['bio'] as String? ?? '';
        _nationality = profile['nationality'] as String? ?? '';
        _teamSupported = profile['team_supported'] as String? ?? '';
        _city = profile['city'] as String? ?? '';
        _isLocal = profile['is_local'] == true;
        _interests = List<String>.from(profile['interests'] as List? ?? []);
        _languages = List<String>.from(profile['languages'] as List? ?? []);
        _matchTypes = List<String>.from(
            profile['match_type_preference'] as List? ?? []);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _markChanged() => setState(() => _hasChanges = true);

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await _repo.updateProfile(_userId, {
        'name': _name,
        'bio': _bio,
        'nationality': _nationality,
        'team_supported': _teamSupported,
        'city': _city,
        'is_local': _isLocal,
        'interests': _interests,
        'languages': _languages,
        'match_type_preference': _matchTypes,
      });
      setState(() {
        _saving = false;
        _hasChanges = false;
        _profile['name'] = _name;
        _profile['bio'] = _bio;
        _profile['nationality'] = _nationality;
        _profile['team_supported'] = _teamSupported;
        _profile['interests'] = _interests;
        _profile['languages'] = _languages;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved ✅'),
              backgroundColor: Color(0xFF135E4B)),
        );
      }
    } catch (_) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save'),
              backgroundColor: Color(0xFFE83535)),
        );
      }
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (file == null) return;
    try {
      final url = await _repo.uploadAvatar(_userId, File(file.path));
      if (url != null) {
        await _repo.updateProfile(_userId, {'avatar_url': url});
        setState(() => _profile['avatar_url'] = url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo updated ✅'),
                backgroundColor: Color(0xFF135E4B)),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed'),
              backgroundColor: Color(0xFFE83535)),
        );
      }
    }
  }

  void _showEditSheet({
    required String label,
    required String currentValue,
    required ValueChanged<String> onSave,
    int maxLines = 1,
  }) {
    final controller = TextEditingController(text: currentValue);
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1A13),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, 24 + bottomPad + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.spaceMono(
                    fontSize: 10, color: const Color(0xFF4CB572),
                    letterSpacing: 2)),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              autofocus: true,
              maxLines: maxLines,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                fillColor: const Color(0xFF152B1E),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4CB572)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.20)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.60))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onSave(controller.text.trim());
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF135E4B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Save',
                        style: GoogleFonts.inter(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D1A13),
        title: Text('Sign out of FIFA LOVE?',
            style: GoogleFonts.spaceGrotesk(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _repo.signOut();
            },
            child: Text('Sign Out',
                style: GoogleFonts.inter(color: const Color(0xFFE83535))),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D1A13),
        title: Text('Delete Account',
            style: GoogleFonts.spaceGrotesk(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This cannot be undone. Type DELETE to confirm.',
                style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.6))),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                fillColor: const Color(0xFF152B1E),
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim() == 'DELETE') {
                Navigator.pop(context);
                await _repo.deleteAccount(_userId);
              }
            },
            child: Text('Delete',
                style: GoogleFonts.inter(color: const Color(0xFFE83535))),
          ),
        ],
      ),
    );
  }

  static const _allLanguages = [
    'English', 'Spanish', 'Portuguese', 'French', 'Arabic',
    'Japanese', 'German', 'Korean', 'Italian', 'Dutch',
    'Russian', 'Hindi', 'Mandarin', 'Turkish', 'Polish',
  ];

  static const _matchTypeOptions = [
    '❤️ Dating & Romance',
    '⚽ Fan Friends',
    '🗺️ Local Guide',
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF080F0C),
        body: Center(
          child: CircularProgressIndicator(
              color: Color(0xFF4CB572), strokeWidth: 2),
        ),
      );
    }

    final completion = _repo.calculateCompletion(_profile);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF080F0C),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    ProfileHeader(
                        profile: _profile, onEditPhoto: _pickAvatar),
                    const SizedBox(height: 16),
                    _buildPremiumCard(context),
                    const SizedBox(height: 16),
                    CompletionBar(
                      score: completion['score'] as int,
                      missing:
                          List<String>.from(completion['missing'] as List),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // FOOTBALL IDENTITY
              const SliverToBoxAdapter(
                  child: SectionHeader("⚽ FOOTBALL IDENTITY", isEditable: true)),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    FieldTile(
                      label: 'NATIONALITY', value: _nationality,
                      icon: Icons.flag_outlined,
                      onTap: () => _showEditSheet(
                        label: 'NATIONALITY',
                        currentValue: _nationality,
                        onSave: (v) {
                          setState(() => _nationality = v);
                          _markChanged();
                        },
                      ),
                    ),
                    FieldTile(
                      label: 'TEAM I SUPPORT',
                      value: _teamSupported,
                      icon: Icons.sports_soccer_outlined,
                      onTap: () => _showEditSheet(
                        label: 'TEAM I SUPPORT',
                        currentValue: _teamSupported,
                        onSave: (v) {
                          setState(() => _teamSupported = v);
                          _markChanged();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('I AM A...',
                              style: GoogleFonts.spaceMono(
                                  fontSize: 9,
                                  color: const Color(0xFFEBF2EE).withValues(alpha: 0.35),
                                  letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _toggleCard('🏠', 'Local', _isLocal, () {
                                setState(() => _isLocal = true);
                                _markChanged();
                              }),
                              const SizedBox(width: 8),
                              _toggleCard('✈️', 'Visiting', !_isLocal, () {
                                setState(() => _isLocal = false);
                                _markChanged();
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_isLocal)
                      FieldTile(
                        label: 'MY CITY', value: _city,
                        icon: Icons.location_city_outlined,
                        onTap: () => _showEditSheet(
                          label: 'MY CITY', currentValue: _city,
                          onSave: (v) {
                            setState(() => _city = v);
                            _markChanged();
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // BASIC INFO
              const SliverToBoxAdapter(
                  child: SectionHeader("👤 BASIC INFO", isEditable: true)),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    FieldTile(
                      label: 'NAME', value: _name,
                      icon: Icons.person_outline,
                      onTap: () => _showEditSheet(
                        label: 'NAME', currentValue: _name,
                        onSave: (v) {
                          setState(() => _name = v);
                          _markChanged();
                        },
                      ),
                    ),
                    FieldTile(
                      label: 'BIO', value: _bio,
                      icon: Icons.edit_outlined, isMultiLine: true,
                      onTap: () => _showEditSheet(
                        label: 'BIO', currentValue: _bio,
                        maxLines: 4,
                        onSave: (v) {
                          setState(() => _bio = v);
                          _markChanged();
                        },
                      ),
                    ),
                    FieldTile(
                      label: 'PHONE',
                      value: _profile['phone_number'] as String? ?? '',
                      icon: Icons.phone_outlined,
                      onTap: () => _showEditSheet(
                        label: 'PHONE',
                        currentValue:
                            _profile['phone_number'] as String? ?? '',
                        onSave: (v) {
                          setState(() => _profile['phone_number'] = v);
                          _markChanged();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // WHAT I'M LOOKING FOR
              const SliverToBoxAdapter(
                  child: SectionHeader("❤️ WHAT I'M LOOKING FOR", isEditable: true)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('I WANT TO...',
                          style: GoogleFonts.spaceMono(
                              fontSize: 9,
                              color: const Color(0xFFEBF2EE).withValues(alpha: 0.35),
                              letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      ..._matchTypeOptions.map((opt) {
                        final isSelected = _matchTypes.contains(opt);
                        final emoji = opt.substring(0, 2);
                        final label = opt.substring(2).trim();
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _matchTypes.remove(opt);
                              } else {
                                _matchTypes.add(opt);
                              }
                            });
                            _markChanged();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF135E4B)
                                  : const Color(0xFF152B1E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4CB572)
                                    : const Color(0xFF1E4A33),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(emoji,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(label,
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFEBF2EE))),
                                ),
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  size: 18,
                                  color: isSelected
                                      ? const Color(0xFF4CB572)
                                      : const Color(0xFFEBF2EE).withValues(alpha: 0.20),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // INTERESTS
              const SliverToBoxAdapter(
                  child: SectionHeader("🎯 MY INTERESTS", isEditable: true)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: InterestChipGrid(
                    selected: _interests,
                    onChanged: (updated) {
                      setState(() => _interests = updated);
                      _markChanged();
                    },
                  ),
                ),
              ),

              // LANGUAGES
              const SliverToBoxAdapter(
                  child: SectionHeader("🗣️ LANGUAGES", isEditable: true)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _allLanguages.map((lang) {
                      final isSelected = _languages.contains(lang);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _languages.remove(lang);
                            } else {
                              _languages.add(lang);
                            }
                          });
                          _markChanged();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF135E4B)
                                : const Color(0xFF152B1E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF4CB572)
                                  : const Color(0xFF1E4A33),
                            ),
                          ),
                          child: Text(lang,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isSelected
                                      ? const Color(0xFFEBF2EE)
                                      : const Color(0xFFEBF2EE).withValues(alpha: 0.4))),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // SETTINGS
              const SliverToBoxAdapter(
                  child: SectionHeader("⚙️ SETTINGS")),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.dark_mode_outlined,
                          color: Color(0xFF4CB572)),
                      title: Text('Dark Mode',
                          style: GoogleFonts.inter(
                              fontSize: 15, color: const Color(0xFFEBF2EE))),
                      trailing: const Switch(
                        value: true,
                        activeThumbColor: Color(0xFF4CB572),
                        onChanged: null,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.language_outlined,
                          color: Color(0xFF4CB572)),
                      title: Text('Language',
                          style: GoogleFonts.inter(
                              fontSize: 15, color: const Color(0xFFEBF2EE))),
                      subtitle: Text('English',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFFEBF2EE).withValues(alpha: 0.40))),
                      trailing: Icon(Icons.chevron_right,
                          color: const Color(0xFFEBF2EE).withValues(alpha: 0.25)),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Multiple languages coming soon!')),
                      ),
                    ),
                  ],
                ),
              ),

              // ACCOUNT
              const SliverToBoxAdapter(
                  child: SectionHeader("👑 ACCOUNT")),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.lock_outline,
                          color: const Color(0xFFEBF2EE).withValues(alpha: 0.40)),
                      title: Text('Change Password',
                          style: GoogleFonts.inter(
                              fontSize: 15, color: const Color(0xFFEBF2EE))),
                      trailing: Icon(Icons.chevron_right,
                          color: const Color(0xFFEBF2EE).withValues(alpha: 0.20)),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Reset password via email coming soon!')),
                      ),
                    ),
                    Divider(color: const Color(0xFF4CB572).withValues(alpha: 0.08)),
                    ListTile(
                      leading: Icon(Icons.logout,
                          color:
                              const Color(0xFFE83535).withValues(alpha: 0.7)),
                      title: Text('SIGN OUT',
                          style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              color: const Color(0xFFE83535)
                                  .withValues(alpha: 0.7))),
                      trailing: Icon(Icons.chevron_right,
                          color: const Color(0xFFEBF2EE).withValues(alpha: 0.2)),
                      onTap: _confirmSignOut,
                    ),
                    ListTile(
                      leading: Icon(Icons.delete_outline,
                          color:
                              const Color(0xFFE83535).withValues(alpha: 0.4)),
                      title: Text('DELETE ACCOUNT',
                          style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              color: const Color(0xFFE83535)
                                  .withValues(alpha: 0.4))),
                      onTap: _confirmDelete,
                    ),
                  ],
                ),
              ),

              // Footer
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: Text('Privacy Policy',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFFEBF2EE)
                                        .withValues(alpha: 0.2))),
                          ),
                          Text(' · ',
                              style: TextStyle(
                                  color: const Color(0xFFEBF2EE)
                                      .withValues(alpha: 0.12))),
                          TextButton(
                            onPressed: () {},
                            child: Text('Terms of Service',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFFEBF2EE)
                                        .withValues(alpha: 0.2))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('FIFA LOVE · World Cup 2026',
                          style: GoogleFonts.spaceMono(
                              fontSize: 8,
                              color: const Color(0xFFEBF2EE).withValues(alpha: 0.12))),
                      SizedBox(height: bottomPad + 80),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating save button
          if (_hasChanges)
            Positioned(
              bottom: bottomPad + 72,
              left: 16, right: 16,
              child: GestureDetector(
                onTap: _saving ? null : _saveProfile,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                        colors: [Color(0xFF135E4B), Color(0xFF4CB572)]),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CB572).withValues(alpha: 0.3),
                        blurRadius: 16, offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _saving
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              Text('Saving...',
                                  style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ],
                          )
                        : Text('Save Changes',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Premium coming soon! ⭐')),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A3025), Color(0xFF0D2018)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
              color: const Color(0xFFF2C233)
                  .withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF2C233)),
                      const SizedBox(width: 6),
                      Text('GO PREMIUM',
                          style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: const Color(0xFFF2C233),
                              letterSpacing: 1.5)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Unlock Global Scouting',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(
                      'Unlimited swipes · See who liked you',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFEBF2EE)
                              .withValues(alpha: 0.5))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2C233)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFF2C233)),
              ),
              child: Text(r'$9.99/mo',
                  style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      color: const Color(0xFFF2C233))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleCard(
      String emoji, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF135E4B)
                : const Color(0xFF152B1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF4CB572)
                  : const Color(0xFF1E4A33),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.40))),
            ],
          ),
        ),
      ),
    );
  }
}
