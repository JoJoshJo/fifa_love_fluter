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
            padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WORLD CUP',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '2026',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: const Color(0xFF4CB572),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Countdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF135E4B).withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF4CB572).withValues(alpha: 0.40)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _daysUntilKickoff(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF2C233),
                        ),
                      ),
                      Text(
                        'DAYS LEFT',
                        style: GoogleFonts.spaceMono(
                          fontSize: 8,
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

          // ─── Tab bar ───
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _tabs.length,
              itemBuilder: (context, i) {
                final tab = _tabs[i];
                final isActive = i == _activeTab;

                return GestureDetector(
                  onTap: () => setState(() => _activeTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
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
                              : Colors.white.withValues(alpha: 0.40),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tab['label'] as String,
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isActive
                                ? const Color(0xFF080F0C)
                                : Colors.white.withValues(alpha: 0.40),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),

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
