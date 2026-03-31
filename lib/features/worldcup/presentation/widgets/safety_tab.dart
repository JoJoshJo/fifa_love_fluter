import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/worldcup_data.dart';

class SafetyTab extends StatefulWidget {
  const SafetyTab({super.key});

  @override
  State<SafetyTab> createState() => _SafetyTabState();
}

class _SafetyTabState extends State<SafetyTab> {
  String _selectedCity = 'Dallas';
  static const _cities = [
    'Dallas', 'Los Angeles', 'Miami', 'New York/New Jersey', 'Atlanta',
    'Houston', 'Philadelphia', 'Seattle', 'Boston', 'Kansas City',
    'San Francisco', 'Vancouver', 'Toronto', 'Guadalajara', 'Mexico City', 'Monterrey'
  ];

  Color _scoreColor(double score) {
    if (score >= 8.0) return const Color(0xFF4CB572);
    if (score >= 7.0) return const Color(0xFFF2C233);
    return const Color(0xFFE83535);
  }

  Widget _card({required Widget child, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? const Color(0xFF1E4A33)),
      ),
      child: child,
    );
  }

  Widget _chip({required String label, required Color bg, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: textColor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = safetyData.firstWhere(
      (d) => d['city'] == _selectedCity,
      orElse: () => safetyData.first,
    );
    final score = (data['safety_score'] as num).toDouble();
    final scoreColor = _scoreColor(score);

    return Column(
      children: [
        // City selector
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _cities.length,
            itemBuilder: (context, i) {
              final city = _cities[i];
              final isActive = city == _selectedCity;
              final d = safetyData.firstWhere(
                (x) => x['city'] == city,
                orElse: () => {'safety_score': 7.0},
              );
              final cs = _scoreColor((d['safety_score'] as num).toDouble());
              return GestureDetector(
                onTap: () => setState(() => _selectedCity = city),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF135E4B) : const Color(0xFF152B1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isActive ? cs : const Color(0xFF1E4A33)),
                  ),
                  child: Text(
                    city,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.45),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            children: [
              // Score card
              _card(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SAFETY SCORE',
                            style: GoogleFonts.spaceMono(
                                fontSize: 9, color: const Color(0xFF4CB572), letterSpacing: 1.5)),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(score.toString(),
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 36, fontWeight: FontWeight.bold, color: scoreColor)),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(' /10',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Colors.white.withValues(alpha: 0.40))),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scoreColor.withValues(alpha: 0.15),
                      ),
                      child: Icon(Icons.shield_outlined, size: 28, color: scoreColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Safe areas
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✅ SAFE AREAS',
                        style: GoogleFonts.spaceMono(
                            fontSize: 9, color: const Color(0xFF4CB572), letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 6,
                      children: (data['best_areas'] as List)
                          .map((area) => _chip(
                                label: area as String,
                                bg: const Color(0xFF135E4B).withValues(alpha: 0.3),
                                textColor: Colors.white.withValues(alpha: 0.80),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Avoid areas
              _card(
                borderColor: const Color(0xFFE83535).withValues(alpha: 0.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚠️ CAUTION AT NIGHT',
                        style: GoogleFonts.spaceMono(
                            fontSize: 9, color: const Color(0xFFE83535), letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 6,
                      children: (data['avoid_at_night'] as List)
                          .map((area) => _chip(
                                label: area as String,
                                bg: const Color(0xFFE83535).withValues(alpha: 0.12),
                                textColor: const Color(0xFFE83535).withValues(alpha: 0.80),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Emergency
              _card(
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined, size: 18, color: Color(0xFF4CB572)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EMERGENCY NUMBER',
                            style: GoogleFonts.spaceMono(
                                fontSize: 9, color: const Color(0xFF4CB572), letterSpacing: 1.5)),
                        const SizedBox(height: 2),
                        Text(data['emergency'] as String,
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Pro tip
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2C233).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: const Color(0xFFF2C233).withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFFF2C233)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data['tip'] as String,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.70),
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
