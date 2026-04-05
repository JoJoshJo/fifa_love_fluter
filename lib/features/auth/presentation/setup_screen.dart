import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../shared/presentation/main_screen.dart';
import '../../me/data/me_repository.dart';
import '../../../core/constants/colors.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _repo = MeRepository();
  int _step = 0;
  String _nationality = '';
  String _nationalityFlag = '';
  String _team = '';
  bool _isLocal = false;
  final List<String> _matchTypes = [];
  final List<String> _selectedCountries = [];
  bool _saving = false;

  String get _userId => SupabaseConfig.client.auth.currentUser?.id ?? '';

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
                      prefixIcon: Icon(Icons.search, color: FifaColors.emeraldSpring),
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
                                color: FifaColors.emeraldSpring, size: 20)
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
    final mutedText = isLight ? FifaColors.mutedTextLight : FifaColors.textMuted;
    
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
                                const Icon(Icons.check_circle, color: FifaColors.emeraldSpring, size: 20),
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
      await _repo.updateProfile(_userId, {
        'nationality': _nationality,
        'team_supported': _team.isNotEmpty ? _team : null,
        'is_local': _isLocal,
        'match_type_preference': _matchTypes,
        'countries_to_match': _selectedCountries,
      });
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong — please try again'),
            backgroundColor: Color(0xFFE83535),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomCenter,
            radius: 1.5,
            colors: [
              FifaColors.emeraldForest.withValues(alpha: isLight ? 0.08 : 0.3),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'STEP ${_step + 1} OF 2',
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            color: FifaColors.emeraldSpring,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_step + 1) / 2,
                        backgroundColor: theme.dividerColor.withValues(alpha: 0.05),
                        valueColor: const AlwaysStoppedAnimation<Color>(FifaColors.emeraldSpring),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _step == 0 ? _buildStep0(context) : _buildStep1(context),
                ),
              ),

              // Bottom buttons
              Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPad + 32),
                child: _step == 0 ? _buildStep0Button() : _buildStep1Buttons(),
              ),
            ],
          ),
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
        const SizedBox(height: 32),
        Text(
          'Your football identity',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28, 
            fontWeight: FontWeight.bold, 
            color: theme.textTheme.displayLarge?.color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'This helps us find your perfect matches',
          style: GoogleFonts.inter(
            fontSize: 14, 
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 32),

        // Nationality
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
                  ? Border.all(color: FifaColors.emeraldSpring.withValues(alpha: 0.4))
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
                Icon(
                  Icons.expand_more,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Team
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
                Expanded(
                  child: Text(
                    _team.isEmpty ? 'Select your team...' : _team,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: _team.isNotEmpty 
                          ? (isLight ? FifaColors.textPrimaryLight : Colors.white) 
                          : (isLight ? FifaColors.mutedTextLight : FifaColors.textMuted),
                      fontWeight: _team.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                const Icon(LucideIcons.chevronDown, size: 18, color: FifaColors.textMuted),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Local or Visiting
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

        // Looking for
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
                color: isSelected
                    ? FifaColors.emeraldForest
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? FifaColors.emeraldSpring
                      : theme.dividerColor.withValues(alpha: 0.1),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: FifaColors.emeraldSpring.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ] : null,
              ),
              child: Row(
                children: [
                  Icon(
                    opt['icon'] as IconData,
                    size: 22,
                    color: isSelected ? Colors.white : FifaColors.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          opt['sub'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isSelected ? Colors.white.withValues(alpha: 0.7) : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    size: 18,
                    color: isSelected
                        ? Colors.white
                        : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
      ],
    );
  }

  Widget _buildStep1(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          'Who do you want to meet?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26, 
            fontWeight: FontWeight.bold, 
            color: theme.textTheme.displayLarge?.color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select countries you want to match with',
          style: GoogleFonts.inter(
            fontSize: 14, 
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Leave empty to meet fans from everywhere',
          style: GoogleFonts.inter(
            fontSize: 13, 
            color: FifaColors.emeraldSpring,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        // Country chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _countriesForNationality.map((c) {
            final name = c['name']!;
            final flag = c['flag']!;
            final isSelected = _selectedCountries.contains(name);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCountries.remove(name);
                  } else {
                    _selectedCountries.add(name);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? FifaColors.emeraldForest
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? FifaColors.emeraldSpring
                        : theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  '$flag $name',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),
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
        backgroundColor: canContinue ? FifaColors.emeraldForest : Theme.of(context).dividerColor.withValues(alpha: 0.05),
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
          color: FifaColors.accent,
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
    final muted = isLight ? FifaColors.mutedTextLight : FifaColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                    color: FifaColors.accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: isSelected ? Colors.white : iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              softWrap: true,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isLight ? FifaColors.textPrimaryLight : Colors.white),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              softWrap: true,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
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
}
