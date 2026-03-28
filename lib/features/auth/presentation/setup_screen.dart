import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../shared/presentation/main_screen.dart';
import '../../me/data/me_repository.dart';

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

  static const _countries = [
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
    {'emoji': '❤️', 'label': 'Dating & Romance', 'sub': 'Find a connection'},
    {'emoji': '⚽', 'label': 'Fan Friends', 'sub': 'Watch matches together'},
    {'emoji': '🗺️', 'label': 'Local Guide', 'sub': 'Show me your city'},
  ];

  void _showNationalityPicker() {
    String search = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1A13),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filtered = _countries.where((c) {
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search country...',
                      hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3)),
                      fillColor: const Color(0xFF152B1E),
                      filled: true,
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF4CB572)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
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
                        title: Text(c['name']!,
                            style: GoogleFonts.inter(
                                fontSize: 15, color: Colors.white)),
                        trailing: sel
                            ? const Icon(Icons.check_circle,
                                color: Color(0xFF4CB572), size: 20)
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
    final controller = TextEditingController(text: _team);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1A13),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TEAM YOU SUPPORT',
                style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: const Color(0xFF4CB572),
                    letterSpacing: 2)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g. Barcelona, Arsenal...',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                fillColor: const Color(0xFF152B1E),
                filled: true,
                prefixIcon: const Icon(Icons.sports_soccer_outlined,
                    color: Color(0xFF4CB572)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF4CB572), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _team = controller.text.trim());
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135E4B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child:
                    Text('Done', style: GoogleFonts.inter(color: Colors.white)),
              ),
            ),
          ],
        ),
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
              backgroundColor: Color(0xFFE83535)),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF080F0C),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomCenter,
            radius: 1.5,
            colors: [
              const Color(0xFF135E4B).withValues(alpha: 0.3),
              const Color(0xFF080F0C),
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
                            color: const Color(0xFF4CB572),
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (_step + 1) / 2,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF4CB572)),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _step == 0 ? _buildStep0() : _buildStep1(),
                ),
              ),

              // Bottom buttons
              Padding(
                padding:
                    EdgeInsets.fromLTRB(24, 12, 24, bottomPad + 32),
                child: _step == 0 ? _buildStep0Button() : _buildStep1Buttons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text('Your football identity ⚽',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6),
        Text('This helps us find your perfect matches',
            style: GoogleFonts.inter(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.40))),
        const SizedBox(height: 32),

        // Nationality
        _label('YOUR NATIONALITY'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showNationalityPicker,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF152B1E),
              borderRadius: BorderRadius.circular(12),
              border: _nationality.isNotEmpty
                  ? Border.all(
                      color: const Color(0xFF4CB572).withValues(alpha: 0.4))
                  : null,
            ),
            child: Row(
              children: [
                if (_nationality.isEmpty)
                  Text('Select your nationality',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.30)))
                else
                  Text('$_nationalityFlag $_nationality',
                      style: GoogleFonts.inter(
                          fontSize: 15, color: Colors.white)),
                const Spacer(),
                Icon(Icons.expand_more,
                    color: Colors.white.withValues(alpha: 0.40)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Team
        _label('TEAM YOU SUPPORT'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showTeamPicker,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF152B1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.sports_soccer_outlined,
                    size: 18,
                    color: const Color(0xFF4CB572).withValues(alpha: 0.6)),
                const SizedBox(width: 12),
                if (_team.isEmpty)
                  Text('Select your team',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.30)))
                else
                  Text(_team,
                      style: GoogleFonts.inter(
                          fontSize: 15, color: Colors.white)),
                const Spacer(),
                Icon(Icons.expand_more,
                    color: Colors.white.withValues(alpha: 0.40)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Local or Visiting
        _label('ARE YOU...'),
        const SizedBox(height: 8),
        Row(
          children: [
            _localVisitCard('🏠', 'I Live Here', _isLocal, () {
              setState(() => _isLocal = true);
            }),
            const SizedBox(width: 10),
            _localVisitCard("✈️", "I'm Visiting", !_isLocal, () {
              setState(() => _isLocal = false);
            }),
          ],
        ),

        const SizedBox(height: 24),

        // Looking for
        _label('LOOKING FOR...'),
        const SizedBox(height: 8),
        ..._matchTypeOptions.map((opt) {
          final label = opt['label']!;
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
                  Text(opt['emoji']!, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(label,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        Text(opt['sub']!,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.45))),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    size: 18,
                    color: isSelected
                        ? const Color(0xFF4CB572)
                        : Colors.white.withValues(alpha: 0.20),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text('Who do you want to meet? 🌍',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6),
        Text('Select countries you want to match with',
            style: GoogleFonts.inter(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.40))),
        const SizedBox(height: 8),
        Text('Leave empty to meet fans from everywhere',
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF4CB572))),
        const SizedBox(height: 24),

        // Country chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _countries.map((c) {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                child: Text(
                  '$flag $name',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
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
            color: Colors.white.withValues(alpha: 0.30),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep0Button() {
    final canContinue = _nationality.isNotEmpty;
    return InkWell(
      onTap: () {
        if (!canContinue) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select your nationality')),
          );
          return;
        }
        setState(() => _step = 1);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: canContinue
              ? const LinearGradient(
                  colors: [Color(0xFF135E4B), Color(0xFF4CB572)])
              : null,
          color: canContinue ? null : const Color(0xFF152B1E),
        ),
        child: Text('Continue →',
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: canContinue
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.25))),
      ),
    );
  }

  Widget _buildStep1Buttons() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _step = 0),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: Text('← Back',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.60))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: _saving ? null : _finish,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                    colors: [Color(0xFF135E4B), Color(0xFF4CB572)]),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Start Matching 🔥',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.spaceMono(
        fontSize: 9,
        color: const Color(0xFF4CB572),
        letterSpacing: 2,
      ),
    );
  }

  Widget _localVisitCard(
      String emoji, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 72,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF135E4B)
                : const Color(0xFF152B1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF4CB572)
                  : const Color(0xFF1E4A33),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
