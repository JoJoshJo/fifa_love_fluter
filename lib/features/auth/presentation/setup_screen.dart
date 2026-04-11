import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../shared/presentation/main_screen.dart';
import '../../../core/constants/colors.dart';
import 'widgets/country_selector_sheet.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _step = 0;
  String _nationality = '';
  String _nationalityFlag = '';
  String _team = '';
  bool _isLocal = false;
  final List<String> _matchTypes = [];
  final List<String> _selectedCountries = [];
  final List<String> _selectedInterests = [];
  bool _saving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String get _userId => SupabaseConfig.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    final user = SupabaseConfig.client.auth.currentUser;
    if (user != null) {
      final meta = user.userMetadata;
      // Pre-fill from Google OAuth or previous signup
      _nameController.text = meta?['name'] ?? meta?['full_name'] ?? meta?['user_name'] ?? '';
      if (meta?['age'] != null) {
        _ageController.text = meta!['age'].toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  static const _worldCupTeams = [
    'Argentina', 'Australia', 'Belgium', 'Bolivia', 'Brazil',
    'Cameroon', 'Canada', 'Chile', 'Colombia', 'Costa Rica',
    'Croatia', 'Czech Republic', 'Denmark', 'Ecuador', 'Egypt',
    'England', 'France', 'Germany', 'Ghana', 'Indonesia',
    'Iran', 'Italy', 'Ivory Coast', 'Jamaica', 'Japan',
    'Mali', 'Mexico', 'Morocco', 'Netherlands', 'New Zealand',
    'Nigeria', 'Panama', 'Paraguay', 'Peru', 'Poland',
    'Portugal', 'Qatar', 'Saudi Arabia', 'Senegal', 'Serbia',
    'South Korea', 'Spain', 'Switzerland', 'Tunisia', 'Turkey',
    'USA', 'Uruguay', 'Venezuela',
  ];

  static const _availableInterests = [
    'Football', 'Music', 'Travel', 'Foodie', 'Art', 'Dance',
    'Photography', 'Fashion', 'Gym', 'Beach', 'Hiking', 'Culture',
    'Nightlife', 'Cooking', 'Yoga', 'Coffee', 'Wine', 'Afrobeats',
    'Samba', 'Pub Culture', 'History', 'Salsa',
  ];

  static const _countriesForNationality = [
    {'name': 'Brazil', 'flag': '🇧🇷'},
    {'name': 'France', 'flag': '🇫🇷'},
    {'name': 'Argentina', 'flag': '🇦🇷'},
    {'name': 'United States', 'flag': '🇺🇸'},
    {'name': 'England', 'flag': '🏴󠁧󠁢󠁥󠁮󠁧󠁿'},
    {'name': 'Germany', 'flag': '🇩🇪'},
    {'name': 'Spain', 'flag': '🇪🇸'},
    {'name': 'Portugal', 'flag': '🇵🇹'},
    {'name': 'Morocco', 'flag': '🇲🇦'},
    {'name': 'Japan', 'flag': '🇯🇵'},
    {'name': 'Nigeria', 'flag': '🇳🇬'},
    {'name': 'Mexico', 'flag': '🇲🇽'},
    {'name': 'Colombia', 'flag': '🇨🇴'},
    {'name': 'Senegal', 'flag': '🇸🇳'},
    {'name': 'Australia', 'flag': '🇦🇺'},
    {'name': 'South Korea', 'flag': '🇰🇷'},
    {'name': 'Netherlands', 'flag': '🇳🇱'},
    {'name': 'Italy', 'flag': '🇮🇹'},
    {'name': 'Belgium', 'flag': '🇧🇪'},
    {'name': 'Canada', 'flag': '🇨🇦'},
  ];

  static const _matchTypeOptions = [
    {'icon': LucideIcons.heart, 'label': 'Dating & Romance', 'sub': 'Find a connection'},
    {'icon': LucideIcons.trophy, 'label': 'Fan Friends', 'sub': 'Watch matches together'},
    {'icon': LucideIcons.map, 'label': 'Local Guide', 'sub': 'Show me your city'},
  ];

  void _showNationalityPicker() {
    final theme = Theme.of(context);
    String search = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filtered = _countriesForNationality.where((c) {
            return c['name']!.toLowerCase().contains(search.toLowerCase());
          }).toList();

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            builder: (_, controller) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    style: theme.textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'Search country...',
                      prefixIcon: Icon(Icons.search, color: TurfArdorColors.emeraldSpring),
                    ),
                    onChanged: (v) => setSheetState(() => search = v),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      final sel = c['name'] == _nationality;
                      return ListTile(
                        leading:
                            Text(c['flag']!, style: const TextStyle(fontSize: 24)),
                        title: Text(
                          c['name']!,
                          style: GoogleFonts.inter(
                            fontSize: 15, 
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: sel
                            ? const Icon(Icons.check_circle,
                                color: TurfArdorColors.emeraldSpring, size: 20)
                            : null,
                        onTap: () {
                          setState(() {
                            _nationality = c['name']!;
                            _nationalityFlag = c['flag']!;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTeamPicker() {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textColor = theme.textTheme.displayLarge?.color;
    final mutedText = isLight ? TurfArdorColors.mutedTextLight : TurfArdorColors.textMuted;
    
    String search = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filtered = _worldCupTeams.where((t) {
            return t.toLowerCase().contains(search.toLowerCase());
          }).toList();

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            builder: (_, controller) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Select Your Team',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    style: GoogleFonts.inter(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search teams...',
                      hintStyle: GoogleFonts.inter(color: mutedText),
                      prefixIcon: const Icon(LucideIcons.search, size: 20, color: Color(0xFF4CB572)),
                      filled: true,
                      fillColor: isLight ? const Color(0xFFF2FAF6) : const Color(0xFF152B1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (v) => setSheetState(() => search = v),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final t = filtered[i];
                      final sel = t == _team;
                      return InkWell(
                        onTap: () {
                          setState(() => _team = t);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: theme.dividerColor.withValues(alpha: 0.05),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                t,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: textColor,
                                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              if (sel)
                                const Icon(Icons.check_circle, color: TurfArdorColors.emeraldSpring, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      final meta = user?.userMetadata ?? {};

      final profileData = {
        'id': _userId,
        'name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : (meta['name'] ?? 'New Fan'),
        'age': int.tryParse(_ageController.text.trim()) ?? meta['age'],
        'gender': meta['gender'],
        'bio': meta['bio'],
        'city': meta['city'],
        'avatar_url': meta['avatar_url'] ?? meta['picture'],
        'nationality': _nationality,
        'team_supported': _team.isNotEmpty ? _team : null,
        'is_local': _isLocal,
        'match_type_preference': _matchTypes,
        'interests': _selectedInterests,
        'countries_to_match': _selectedCountries,
      }..removeWhere((_, v) => v == null);

      await SupabaseConfig.client.from('profiles').upsert(profileData);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('[SETUP] Upsert error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save profile. Please try again.\n${e.toString()}'),
            backgroundColor: const Color(0xFFE83535),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 10),
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  void _nextStep() {
    if (_step == 0) {
      if (_nameController.text.trim().isEmpty) return;
      if (_nationality.isEmpty) return;
      if (_team.isEmpty) return;
      if (_matchTypes.isEmpty) return;
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (_selectedCountries.isEmpty) return;
      setState(() => _step = 2);
    } else if (_step == 2) {
      if (_selectedInterests.length < 3) return;
      _finish();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, size: 20),
                      onPressed: _prevStep,
                    ),
                  const Spacer(),
                  // Progress
                  Text(
                    'Step ${_step + 1} of 3',
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: TurfArdorColors.emeraldSpring,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _step == 0 
                  ? _buildStep0(context) 
                  : (_step == 1 ? _buildStep1(context) : _buildStep2(context)),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  child: Center(
                    child: Text(
                      _step == 2 ? 'Let\'s Go!' : 'Continue',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep0(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your football identity',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28, 
            fontWeight: FontWeight.bold, 
            color: theme.textTheme.displayLarge?.color,
          ),
        ),
        const SizedBox(height: 32),
        _label(context, 'YOUR NAME'),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            prefixIcon: Icon(Icons.person_outline, color: TurfArdorColors.emeraldSpring),
          ),
        ),
        const SizedBox(height: 20),
        _label(context, 'YOUR AGE'),
        const SizedBox(height: 8),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: 'e.g. 24',
            prefixIcon: Icon(Icons.cake_outlined, color: TurfArdorColors.emeraldSpring),
          ),
        ),
        const SizedBox(height: 20),
        _label(context, 'YOUR NATIONALITY'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showNationalityPicker,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(12),
              border: _nationality.isNotEmpty
                  ? Border.all(color: TurfArdorColors.emeraldSpring.withValues(alpha: 0.4))
                  : null,
            ),
            child: Row(
              children: [
                if (_nationality.isEmpty)
                  Text(
                    'Select your nationality',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    ),
                  )
                else
                  Text(
                    '$_nationalityFlag $_nationality',
                    style: GoogleFonts.inter(
                      fontSize: 15, 
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const Spacer(),
                Icon(Icons.expand_more, color: theme.textTheme.bodySmall?.color),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _label(context, 'TEAM YOU SUPPORT'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showTeamPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFF2FAF6) : const Color(0xFF152B1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLight ? const Color(0xFFE8DDD0) : const Color(0xFF1E4A33),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.trophy, size: 18, color: Color(0xFF4CB572)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _team.isEmpty ? 'Select your team...' : _team,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: _team.isNotEmpty 
                          ? (isLight ? TurfArdorColors.textPrimaryLight : Colors.white) 
                          : (isLight ? TurfArdorColors.mutedTextLight : TurfArdorColors.textMuted),
                    ),
                  ),
                ),
                const Icon(LucideIcons.chevronDown, size: 18, color: TurfArdorColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _label(context, 'ARE YOU...'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _localVisitCard(
                title: "I'm a Local",
                subtitle: "I live here",
                icon: LucideIcons.home,
                iconColor: Colors.white,
                isSelected: _isLocal == true,
                onTap: () => setState(() => _isLocal = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _localVisitCard(
                title: "Visiting",
                subtitle: "In for the games",
                icon: LucideIcons.plane,
                iconColor: isLight ? const Color(0xFF0D2B1E) : Colors.white,
                isSelected: _isLocal == false,
                onTap: () => setState(() => _isLocal = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _label(context, 'LOOKING FOR...'),
        const SizedBox(height: 8),
        ..._matchTypeOptions.map((opt) {
          final label = opt['label'] as String;
          final isSelected = _matchTypes.contains(label);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _matchTypes.remove(label);
                } else {
                  _matchTypes.add(label);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? TurfArdorColors.emeraldForest : theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? TurfArdorColors.emeraldSpring : theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(opt['icon'] as IconData, size: 22, color: isSelected ? Colors.white : TurfArdorColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color)),
                        Text(opt['sub'] as String, style: GoogleFonts.inter(fontSize: 12, color: isSelected ? Colors.white.withValues(alpha: 0.7) : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                  Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, size: 18, color: isSelected ? Colors.white : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.2)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep1(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who do you want to meet?',
          style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => CountrySelectorSheet(
                selectedCountries: _selectedCountries,
                onSelect: (selected) {
                  setState(() => _selectedCountries..clear()..addAll(selected));
                },
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFF2F2F2) : theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.globe, size: 20, color: isLight ? TurfArdorColors.emeraldForest : TurfArdorColors.emeraldSpring),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCountries.isEmpty ? "Select countries to match with..." : "${_selectedCountries.length} countries selected",
                    style: GoogleFonts.inter(fontSize: 15, color: _selectedCountries.isEmpty ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5) : theme.textTheme.bodyLarge?.color, fontWeight: _selectedCountries.isEmpty ? FontWeight.normal : FontWeight.bold),
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 18, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedCountries.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedCountries.map((c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: TurfArdorColors.emeraldSpring.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TurfArdorColors.emeraldSpring.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: TurfArdorColors.emeraldSpring)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _selectedCountries.remove(c)),
                    child: const Icon(LucideIcons.x, size: 12, color: TurfArdorColors.emeraldSpring),
                  ),
                ],
              ),
            )).toList(),
          ),

        const SizedBox(height: 24),
        Text(
          'Tip: More countries = more matches in your feed',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep0Button() {
    final canContinue = _nationality.isNotEmpty;
    return ElevatedButton(
      onPressed: () {
        if (!canContinue) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select your nationality'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        setState(() => _step = 1);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: canContinue ? TurfArdorColors.emeraldForest : Theme.of(context).dividerColor.withValues(alpha: 0.05),
        foregroundColor: canContinue ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
        elevation: canContinue ? 2 : 0,
      ),
      child: const Text('Continue →'),
    );
  }

  Widget _buildStep1Buttons() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() => _step = 0),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
              foregroundColor: theme.textTheme.bodyMedium?.color,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('← Back'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saving ? null : _finish,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('Start Matching'),
          ),
        ),
      ],
    );
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.spaceMono(
          fontSize: 11,
          color: TurfArdorColors.accent,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _localVisitCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final muted = isLight ? TurfArdorColors.mutedTextLight : TurfArdorColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF135E4B), Color(0xFF4CB572)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isLight ? Colors.white : const Color(0xFF0D1A13)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isLight ? const Color(0xFFE8DDD0) : const Color(0xFF1E4A33)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: TurfArdorColors.accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: isSelected ? Colors.white : iconColor),
            const SizedBox(height: 8),
            Text(
              title,
              softWrap: true,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isLight ? TurfArdorColors.textPrimaryLight : Colors.white),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              softWrap: true,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textColor = theme.textTheme.displayLarge?.color;
    final mutedText = isLight ? TurfArdorColors.mutedTextLight : TurfArdorColors.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR INTERESTS',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Beyond the pitch, what brings you joy? Select at least 3 things to round out your profile.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: mutedText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: _availableInterests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            
            // Categorical styling
            Color bg;
            Color txt;
            
            if (['Football', 'Gym', 'Yoga'].contains(interest)) {
              bg = isSelected ? const Color(0xFF135E4B) : const Color(0xFFA4E4C1);
              txt = isSelected ? Colors.white : const Color(0xFF004B3A);
            } else if (['Samba', 'Music', 'Art', 'Dance', 'Afrobeats', 'Salsa', 'History', 'Culture'].contains(interest)) {
              bg = isSelected ? const Color(0xFF8A3058) : const Color(0xFFFFF0F5);
              txt = isSelected ? Colors.white : const Color(0xFF8A3058);
            } else if (['Beach', 'Hiking', 'Travel'].contains(interest)) {
              bg = isSelected ? const Color(0xFF5A4500) : const Color(0xFFFFF8E1);
              txt = isSelected ? Colors.white : const Color(0xFF5A4500);
            } else {
              bg = isSelected ? const Color(0xFF135E4B) : const Color(0xFFA4E4C1);
              txt = isSelected ? Colors.white : const Color(0xFF004B3A);
            }

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedInterests.remove(interest);
                  } else {
                    _selectedInterests.add(interest);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(24),
                  border: isSelected ? Border.all(color: Colors.white.withValues(alpha: 0.3)) : null,
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: bg.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ] : null,
                ),
                child: Text(
                  interest,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: txt,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
        if (_selectedInterests.length < 3 && _selectedInterests.isNotEmpty)
          Row(
            children: [
              const Icon(LucideIcons.info, size: 16, color: TurfArdorColors.emeraldSpring),
              const SizedBox(width: 8),
              Text(
                'Please select ${3 - _selectedInterests.length} more...',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: TurfArdorColors.emeraldSpring,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
