import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                orElse: () => {'flag': '🌍'},
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
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    '${cityData['flag']} $city',
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
                      Text('🍽️',
                          style: TextStyle(
                              fontSize: 48,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3))),
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
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final r = filtered[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Emoji icon
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                r['icon'] as String,
                                style: const TextStyle(fontSize: 26),
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
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).textTheme.titleLarge?.color,
                                        ),
                                      ),
                                    ),
                                    // Vibe tag
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        r['vibe'] as String,
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 8,
                                          color: Theme.of(context).primaryColor,
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
                                        color: FifaColors.gold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.star_rounded,
                                        size: 12,
                                        color: FifaColors.gold),
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
