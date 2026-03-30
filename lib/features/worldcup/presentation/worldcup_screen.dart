import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/schedule_tab.dart';
import 'widgets/food_tab.dart';
import 'widgets/safety_tab.dart';
import 'widgets/rides_tab.dart';

class WorldCupScreen extends StatefulWidget {
  const WorldCupScreen({super.key});

  @override
  State<WorldCupScreen> createState() => _WorldCupScreenState();
}

class _WorldCupScreenState extends State<WorldCupScreen> {
  int _activeTab = 0;

  static const _tabs = [
    {'label': 'Schedule', 'icon': Icons.calendar_today_outlined},
    {'label': 'Food',     'icon': Icons.restaurant_outlined},
    {'label': 'Safety',   'icon': Icons.shield_outlined},
    {'label': 'Rides',    'icon': Icons.directions_car_outlined},
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
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF080F0C),
      body: Column(
        children: [
          // ─── Header ───
          Container(
            padding: EdgeInsets.fromLTRB(16, topPad + 16, 16, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'WORLD CUP',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEBF2EE),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '2026',
                          style: GoogleFonts.spaceMono(
                            fontSize: 13,
                            color: const Color(0xFF4CB572),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'THE ROAD TO THE FINALS',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        color: const Color(0xFF9BB3AF),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Countdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF135E4B).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF4CB572).withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _daysUntilKickoff().replaceAll(' 🔥', ''),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF2C233),
                        ),
                      ),
                      Text(
                        'DAYS LEFT',
                        style: GoogleFonts.spaceMono(
                          fontSize: 7,
                          color: const Color(0xFF4CB572),
                          letterSpacing: 1,
                        ),
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
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF135E4B),
                          Color(0xFF080F0C),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.stadium_outlined,
                      size: 64,
                      color: const Color(0xFF4CB572).withValues(alpha: 0.3),
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
                            const Color(0xFF080F0C).withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2C233).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFF2C233).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              'LIVE VENUE',
                              style: GoogleFonts.spaceMono(
                                fontSize: 8,
                                color: const Color(0xFFF2C233),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AT&T STADIUM, DALLAS',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                          ? const Color(0xFF4CB572)
                          : const Color(0xFF152B1E),
                      borderRadius: BorderRadius.circular(20),
                      border: isActive
                          ? null
                          : Border.all(color: const Color(0xFF1E4A33)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab['icon'] as IconData,
                          size: 14,
                          color: isActive
                              ? const Color(0xFF080F0C)
                              : const Color(0xFFEBF2EE).withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tab['label'] as String,
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive
                                ? const Color(0xFF080F0C)
                                : const Color(0xFFEBF2EE).withValues(alpha: 0.4),
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
          Divider(height: 1, color: const Color(0xFF4CB572).withValues(alpha: 0.1)),

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
