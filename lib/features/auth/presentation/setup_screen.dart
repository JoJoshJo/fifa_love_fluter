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
  String? _nationality;
  String? _nationalityFlag;
  String _team = '';
  bool _isLocal = false;
  final List<String> _matchTypes = [];
  bool _saving = false;

  String get _userId =>
      SupabaseConfig.client.auth.currentUser?.id ?? '';

  static const _matchTypeOptions = [
    '❤️ Dating & Romance',
    '⚽ Fan Friends',
    '🗺️ Local Guide',
  ];

  static const _countries = [
    {'name': 'Argentina', 'flag': '🇦🇷'},
    {'name': 'Australia', 'flag': '🇦🇺'},
    {'name': 'Brazil', 'flag': '🇧🇷'},
    {'name': 'Canada', 'flag': '🇨🇦'},
    {'name': 'Colombia', 'flag': '🇨🇴'},
    {'name': 'England', 'flag': '🏴󠁧󠁢󠁥󠁮󠁧󠁿'},
    {'name': 'France', 'flag': '🇫🇷'},
    {'name': 'Germany', 'flag': '🇩🇪'},
    {'name': 'Ghana', 'flag': '🇬🇭'},
    {'name': 'Italy', 'flag': '🇮🇹'},
    {'name': 'Japan', 'flag': '🇯🇵'},
    {'name': 'Mexico', 'flag': '🇲🇽'},
    {'name': 'Morocco', 'flag': '🇲🇦'},
    {'name': 'Netherlands', 'flag': '🇳🇱'},
    {'name': 'Nigeria', 'flag': '🇳🇬'},
    {'name': 'Portugal', 'flag': '🇵🇹'},
    {'name': 'Saudi Arabia', 'flag': '🇸🇦'},
    {'name': 'Senegal', 'flag': '🇸🇳'},
    {'name': 'South Korea', 'flag': '🇰🇷'},
    {'name': 'Spain', 'flag': '🇪🇸'},
    {'name': 'USA', 'flag': '🇺🇸'},
    {'name': 'Uruguay', 'flag': '🇺🇾'},
  ];

  Future<void> _continue() async {
    if (_nationality == null) return;

    setState(() => _saving = true);
    try {
      await _repo.updateProfile(_userId, {
        'nationality': _nationality,
        'team_supported': _team.isNotEmpty ? _team : null,
        'is_local': _isLocal,
        'match_type_preference': _matchTypes,
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

  void _showCountryPicker() {
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
            final name = c['name']!.toLowerCase();
            return name.contains(search.toLowerCase());
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
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFF4CB572)),
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
                      final isSelected = c['name'] == _nationality;
                      return ListTile(
                        leading: Text(c['flag']!,
                            style: const TextStyle(fontSize: 24)),
                        title: Text(c['name']!,
                            style: GoogleFonts.inter(
                                fontSize: 15, color: Colors.white)),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: Color(0xFF4CB572), size: 20)
                            : null,
                        onTap: () {
                          setState(() {
                            _nationality = c['name'];
                            _nationalityFlag = c['flag'];
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

  @override
  Widget build(BuildContext context) {
    final canContinue = _nationality != null;

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const SizedBox(height: 48),
                Text(
                  'One last thing! 👋',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us a bit about yourself\nto start matching',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 40),

                // NATIONALITY PICKER
                _buildLabel('YOUR NATIONALITY'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showCountryPicker,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF152B1E),
                      borderRadius: BorderRadius.circular(12),
                      border: _nationality != null
                          ? Border.all(
                              color: const Color(0xFF4CB572)
                                  .withValues(alpha: 0.4))
                          : null,
                    ),
                    child: Row(
                      children: [
                        if (_nationality != null) ...[
                          Text('$_nationalityFlag $_nationality',
                              style: GoogleFonts.inter(
                                  fontSize: 15, color: Colors.white)),
                        ] else ...[
                          Text('Select your nationality',
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: Colors.white
                                      .withValues(alpha: 0.30))),
                        ],
                        const Spacer(),
                        Icon(Icons.expand_more,
                            color: Colors.white.withValues(alpha: 0.40)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // TEAM PICKER
                _buildLabel('TEAM YOU SUPPORT'),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _team,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'e.g. Barcelona, Arsenal...',
                    hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.30)),
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
                      borderSide: const BorderSide(
                          color: Color(0xFF4CB572), width: 1.5),
                    ),
                  ),
                  onChanged: (v) => _team = v.trim(),
                ),

                const SizedBox(height: 24),

                // LOCAL / VISITING
                _buildLabel('I AM A...'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _toggleCard('🏠', 'Local', _isLocal, () {
                      setState(() => _isLocal = true);
                    }),
                    const SizedBox(width: 8),
                    _toggleCard('✈️', 'Visiting', !_isLocal, () {
                      setState(() => _isLocal = false);
                    }),
                  ],
                ),

                const SizedBox(height: 24),

                // WHAT I'M LOOKING FOR
                _buildLabel('I WANT TO...'),
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
                                    color: Colors.white)),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
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

                const SizedBox(height: 32),

                // CONTINUE BUTTON
                InkWell(
                  onTap: canContinue && !_saving ? _continue : null,
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: canContinue
                          ? const LinearGradient(
                              colors: [Color(0xFF135E4B), Color(0xFF4CB572)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: canContinue ? null : const Color(0xFF152B1E),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Start Matching 🔥',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: canContinue
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.spaceMono(
        fontSize: 10,
        color: const Color(0xFF4CB572),
        letterSpacing: 2,
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
