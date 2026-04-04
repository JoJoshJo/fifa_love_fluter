import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/colors.dart';
import 'widgets/schedule_tab.dart';
import 'widgets/food_tab.dart';
import 'widgets/safety_tab.dart';
import 'widgets/rides_tab.dart';

class WorldCupScreen extends StatefulWidget {
  const WorldCupScreen({super.key});

  @override
  State<WorldCupScreen> createState() => _WorldCupScreenState();
}

class _WorldCupScreenState extends State<WorldCupScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _tabs = [
    {'label': 'Schedule', 'icon': LucideIcons.calendar},
    {'label': 'Food',     'icon': LucideIcons.utensils},
    {'label': 'Safety',   'icon': LucideIcons.shield},
    {'label': 'Rides',    'icon': LucideIcons.car},
  ];

  String _daysUntilKickoff() {
    final kickoff = DateTime(2026, 6, 11);
    final now = DateTime.now();
    final diff = kickoff.difference(now).inDays;
    if (diff <= 0) return 'LIVE 🔥';
    return diff.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? FifaColors.lightBackground : FifaColors.darkBackground;
    final text = isLight ? FifaColors.textPrimaryLight : FifaColors.textPrimaryDark;
    const accentGreen = FifaColors.accent;
    const accentDark = FifaColors.accentDark;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ─── Header ───
          Container(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 16),
            color: bg,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WORLD CUP 2026',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          color: const Color(0xFFF2C233),
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The Finals',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: text,
                        ),
                      ),
                    ],
                  ),
                ),

                // Countdown Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1), // champagne glow
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF2C233), width: 1.5), // gold
                  ),
                  child: Column(
                    children: [
                      Text(
                        _daysUntilKickoff().replaceAll(' 🔥', ''),
                        style: GoogleFonts.spaceMono(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFC62828), // red urgency
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: const [
                                Color(0xFF5A4500),
                                Color(0xFFF2C233),
                                Color(0xFF5A4500),
                              ],
                              stops: [
                                _controller.value - 0.2,
                                _controller.value,
                                _controller.value + 0.2,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'DAYS',
                              style: GoogleFonts.spaceMono(
                                fontSize: 9,
                                color: Colors.white, // color will be masked
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Stadium Hero Image ───
          Container(
            height: 160,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Breathing Hero Image with slow gradient shift
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.lerp(const Color(0xFF004B3A), const Color(0xFF135E4B), _controller.value)!,
                              const Color(0xFF4CB572),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Center(
                    child: Icon(
                      LucideIcons.mapPin,
                      size: 64,
                      color: accentGreen.withValues(alpha: 0.15),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            bg,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: isLight ? Border.all(
                                color: accentGreen.withValues(alpha: 0.2),
                              ) : null,
                            ),
                            child: Text(
                              'LIVE VENUE',
                              style: GoogleFonts.spaceMono(
                                fontSize: 8,
                                color: accentGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AT&T STADIUM, DALLAS',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // ─── Tab bar ───
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = i == _activeTab;

                return GestureDetector(
                  onTap: () => setState(() => _activeTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? accentDark
                          : (isLight ? FifaColors.lightCard : FifaColors.darkCard),
                      borderRadius: BorderRadius.circular(20),
                      border: isActive
                          ? null
                          : (isLight ? Border.all(color: FifaColors.lightBorder) : null),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab['icon'] as IconData,
                          size: 14,
                          color: isActive
                              ? Colors.white
                              : text.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                          Text(
                            (tab['label'] as String).toUpperCase(),
                            style: GoogleFonts.spaceMono(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: isActive
                                  ? Colors.white
                                  : (isLight ? const Color(0xFF9BB3AF) : Colors.white38),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          
          const SizedBox(height: 8),

          // Divider
          Divider(height: 1, color: isLight ? FifaColors.lightBorder : Colors.white.withValues(alpha: 0.1)),

          // ─── Tab content ───
          Expanded(
            child: IndexedStack(
              index: _activeTab,
              children: const [
                ScheduleTab(),
                FoodTab(),
                SafetyTab(),
                RidesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
