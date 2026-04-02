import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fifalove_mobile/features/worldcup/data/worldcup_data.dart';

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
    if (score >= 8.0) return FifaColors.accent;
    if (score >= 7.0) return FifaColors.gold;
    return FifaColors.error;
  }

  Widget _card({required Widget child, Color? borderColor}) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? FifaColors.lightCard : FifaColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: isLight ? Border.all(color: borderColor ?? FifaColors.lightBorder) : null,
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    const accentGreen = FifaColors.accent;
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
              return GestureDetector(
                onTap: () => setState(() => _selectedCity = city),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? accentGreen : (isLight ? FifaColors.lightCard : FifaColors.darkCard),
                    borderRadius: BorderRadius.circular(16),
                    border: isLight ? Border.all(color: isActive ? accentGreen : FifaColors.lightBorder) : null,
                  ),
                  child: Text(
                    city,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isActive ? Colors.white : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.45),
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
                                fontSize: 9, color: accentGreen, letterSpacing: 1.5)),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(score.toString(),
                                style: GoogleFonts.playfairDisplay(
                                    fontSize: 36, fontWeight: FontWeight.bold, color: scoreColor)),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 32),
                              child: Text(' /10',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.40))),
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
                      child: Icon(LucideIcons.shield, size: 24, color: scoreColor),
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
                    Row(
                      children: [
                        const Icon(LucideIcons.checkCircle, size: 14, color: accentGreen),
                        const SizedBox(width: 4),
                        Text('SAFE AREAS',
                            style: GoogleFonts.spaceMono(
                                fontSize: 9, color: accentGreen, letterSpacing: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 6,
                      children: (data['best_areas'] as List)
                          .map((area) => _chip(
                                label: area as String,
                                bg: accentGreen.withValues(alpha: 0.1),
                                textColor: accentGreen,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Avoid areas
              _card(
                borderColor: const Color(0xFFE83535).withValues(alpha: 0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.alertTriangle,
                            size: 14, color: FifaColors.error),
                        const SizedBox(width: 4),
                        Text('CAUTION AT NIGHT',
                            style: GoogleFonts.spaceMono(
                                fontSize: 9, color: FifaColors.error, letterSpacing: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 6,
                      children: (data['avoid_at_night'] as List)
                          .map((area) => _chip(
                                label: area as String,
                                bg: FifaColors.error.withValues(alpha: 0.12),
                                textColor: FifaColors.error.withValues(alpha: 0.80),
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
                    const Icon(LucideIcons.phone, size: 18, color: accentGreen),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EMERGENCY NUMBER',
                            style: GoogleFonts.spaceMono(
                                fontSize: 9, color: accentGreen, letterSpacing: 1.5)),
                        const SizedBox(height: 2),
                        Text(data['emergency'] as String,
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
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
                  color: FifaColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: FifaColors.gold.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.lightbulb, size: 18, color: FifaColors.gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data['tip'] as String,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.70),
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
