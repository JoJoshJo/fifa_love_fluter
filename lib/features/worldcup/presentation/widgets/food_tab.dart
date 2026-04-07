import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fifalove_mobile/core/constants/colors.dart';
import 'package:fifalove_mobile/features/worldcup/data/worldcup_data.dart';

class FoodTab extends StatefulWidget {
  const FoodTab({super.key});

  @override
  State<FoodTab> createState() => _FoodTabState();
}

class _FoodTabState extends State<FoodTab> {
  String _selectedCity = 'Dallas';

  // Cities that have restaurant data
  static const _availableCities = [
    'Dallas', 'Los Angeles', 'Miami', 'New York/New Jersey', 'Atlanta',
    'Houston', 'Philadelphia', 'Seattle', 'Boston', 'Kansas City',
    'San Francisco', 'Vancouver', 'Toronto', 'Guadalajara', 'Mexico City', 'Monterrey'
  ];

  List<Map<String, dynamic>> get _filtered =>
      restaurants.where((r) => r['city'] == _selectedCity).toList();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final text = isLight ? TurfArdorColors.textPrimaryLight : TurfArdorColors.textPrimaryDark;
    const accentGreen = TurfArdorColors.accent;
    final filtered = _filtered;

    return Column(
      children: [
        // ─── City selector chips ───
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _availableCities.length,
            itemBuilder: (context, i) {
              final city = _availableCities[i];
              final isActive = city == _selectedCity;

              // Find flag for city
              final cityData = hostCities.firstWhere(
                (c) => c['name'] == city,
                orElse: () => {'flag': LucideIcons.globe},
              );

              return GestureDetector(
                onTap: () => setState(() => _selectedCity = city),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? accentGreen
                        : (isLight ? TurfArdorColors.lightCard : TurfArdorColors.darkCard),
                    borderRadius: BorderRadius.circular(16),
                    border: isLight ? Border.all(
                      color: isActive
                          ? accentGreen
                          : TurfArdorColors.lightBorder,
                    ) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(builder: (context) {
                        final flag = cityData['flag'];
                        return flag is IconData
                            ? Icon(flag, size: 14, color: isActive ? Colors.white : accentGreen.withValues(alpha: 0.5))
                            : Text(flag, style: const TextStyle(fontSize: 14));
                      }),
                      const SizedBox(width: 8),
                      Text(
                        city,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isActive
                              ? Colors.white
                              : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.45),
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ─── Restaurant list ───
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.utensils,
                          size: 48,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(
                        'No restaurants listed yet\nfor $_selectedCity',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24, top: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final r = filtered[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isLight ? TurfArdorColors.lightCard : TurfArdorColors.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isLight ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ] : null,
                        border: isLight ? Border.all(color: TurfArdorColors.lightBorder) : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Emoji icon
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: accentGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                r['icon'] as IconData,
                                size: 24,
                                color: accentGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r['name'] as String,
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: text,
                                        ),
                                      ),
                                    ),
                                    // Vibe tag
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: accentGreen.withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        r['vibe'] as String,
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 8,
                                          color: accentGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    Text(
                                      r['cuisine'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodySmall?.color
                                            ?.withValues(alpha: 0.50),
                                      ),
                                    ),
                                    Text(
                                      ' · ',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodySmall?.color
                                            ?.withValues(alpha: 0.30),
                                      ),
                                    ),
                                    Text(
                                      r['price'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: TurfArdorColors.gold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(LucideIcons.star,
                                        size: 12,
                                        color: TurfArdorColors.gold),
                                    const SizedBox(width: 2),
                                    Text(
                                      (r['rating'] as double).toString(),
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 11,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                Text(
                                  r['description'] as String,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
