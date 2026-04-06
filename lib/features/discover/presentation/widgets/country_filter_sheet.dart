import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CountryFilterSheet extends StatefulWidget {
  final List<String> selected;
  final Function(List<String>) onApply;

  const CountryFilterSheet({
    super.key,
    required this.selected,
    required this.onApply,
  });

  @override
  State<CountryFilterSheet> createState() => _CountryFilterSheetState();
}

class _CountryFilterSheetState extends State<CountryFilterSheet> {
  late List<String> _selected;
  String _search = '';
  bool _showAll = false;

  // 2026 World Cup + common fan countries
  static const List<String> _worldCupCountries = [
    'Argentina', 'Australia', 'Belgium', 'Brazil', 'Canada',
    'Colombia', 'Croatia', 'Ecuador', 'England', 'France',
    'Germany', 'Ghana', 'Italy', 'Japan', 'Mexico',
    'Morocco', 'Netherlands', 'Nigeria', 'Peru', 'Poland',
    'Portugal', 'Saudi Arabia', 'Senegal', 'South Korea', 'Spain', 'USA',
  ];

  static const List<String> _extendedCountries = [
    'Albania', 'Algeria', 'Angola', 'Armenia', 'Azerbaijan',
    'Bolivia', 'Bosnia', 'Cameroon', 'Chile', 'China',
    'Costa Rica', 'Cuba', 'Czech Republic', 'Denmark', 'Egypt',
    'Ethiopia', 'Finland', 'Georgia', 'Greece', 'Honduras',
    'Hungary', 'India', 'Indonesia', 'Iran', 'Iraq',
    'Ireland', 'Israel', 'Ivory Coast', 'Jamaica', 'Jordan',
    'Kazakhstan', 'Kenya', 'Libya', 'Malaysia', 'Mali',
    'New Zealand', 'North Macedonia', 'Norway', 'Pakistan',
    'Palestine', 'Panama', 'Paraguay', 'Philippines', 'Romania',
    'Russia', 'Rwanda', 'Scotland', 'Serbia', 'Slovakia',
    'Slovenia', 'South Africa', 'Sweden', 'Switzerland',
    'Syria', 'Thailand', 'Tunisia', 'Turkey', 'Uganda',
    'Ukraine', 'United Arab Emirates', 'Uruguay', 'Uzbekistan',
    'Venezuela', 'Vietnam', 'Wales', 'Zambia', 'Zimbabwe',
  ];

  static const Map<String, String> _flags = {
    'Argentina': '🇦🇷', 'Australia': '🇦🇺', 'Belgium': '🇧🇪',
    'Brazil': '🇧🇷', 'Canada': '🇨🇦', 'Colombia': '🇨🇴',
    'Croatia': '🇭🇷', 'Ecuador': '🇪🇨', 'England': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
    'France': '🇫🇷', 'Germany': '🇩🇪', 'Ghana': '🇬🇭',
    'Italy': '🇮🇹', 'Japan': '🇯🇵', 'Mexico': '🇲🇽',
    'Morocco': '🇲🇦', 'Netherlands': '🇳🇱', 'Nigeria': '🇳🇬',
    'Peru': '🇵🇪', 'Poland': '🇵🇱', 'Portugal': '🇵🇹',
    'Saudi Arabia': '🇸🇦', 'Senegal': '🇸🇳', 'South Korea': '🇰🇷',
    'Spain': '🇪🇸', 'USA': '🇺🇸',
  };

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selected);
  }

  List<String> get _displayedCountries {
    final base = _showAll
        ? [..._worldCupCountries, ..._extendedCountries]
        : _worldCupCountries;
    if (_search.isEmpty) return base;
    return base
        .where((c) => c.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  String _flag(String country) => _flags[country] ?? '🌍';

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? Colors.white : const Color(0xFF0D1A13);
    final handleColor = isLight ? const Color(0xFFE0D6C8) : Colors.white.withValues(alpha: 0.2);
    const labelColor = Color(0xFFE8437A); // Pink for Discover flow
    final textColor = isLight ? const Color(0xFF1A1A1A) : Colors.white;
    final subtextColor = isLight ? const Color(0xFF8B7355) : Colors.white.withValues(alpha: 0.5);
    final searchFill = isLight ? const Color(0xFFFDF2F5) : const Color(0xFF2B151E); // Soft pink tint
    final searchHint = isLight ? const Color(0xFFB39B9F) : Colors.white.withValues(alpha: 0.4);
    final searchBorder = isLight ? const Color(0xFFF0E8EB) : Colors.transparent;
    final chipUnselectedBg = isLight ? const Color(0xFFF5F0E8) : const Color(0xFF2B151E);
    final chipUnselectedBorder = isLight ? const Color(0xFFE8DDD0) : Colors.white.withValues(alpha: 0.12);
    final chipSelectedBg = isLight ? const Color(0xFFFCE4EC) : const Color(0xFF880E4F); // Light/Dark pink
    const chipSelectedBorder = Color(0xFFE8437A);
    final chipUnselectedText = isLight ? const Color(0xFF3D3025) : Colors.white.withValues(alpha: 0.7);
    final chipSelectedText = isLight ? const Color(0xFF880E4F) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'MATCH WITH FANS FROM',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: labelColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _selected.clear()),
                      child: Text(
                        'Clear all',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: const Color(0xFFE83535)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onApply(_selected);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Apply',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: const Color(0xFFE8437A)),
                      ),
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextFormField(
                  onChanged: (v) => setState(() => _search = v),
                  style: GoogleFonts.inter(fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search countries…',
                    hintStyle: GoogleFonts.inter(fontSize: 14, color: searchHint),
                    prefixIcon: const Icon(Icons.search, color: labelColor, size: 18),
                    filled: true,
                    fillColor: searchFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: searchBorder, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: searchBorder, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE8437A), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Country chips grid
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (_displayedCountries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.searchX,
                                size: 48,
                                color: labelColor.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'No countries found',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try a different search term',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _displayedCountries.map((country) {
                          final isSelected = _selected.contains(country);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selected.remove(country);
                                } else {
                                  _selected.add(country);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? chipSelectedBg : chipUnselectedBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? chipSelectedBorder : chipUnselectedBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_flag(country),
                                      style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Text(
                                    country,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected ? chipSelectedText : chipUnselectedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),
                    if (!_showAll)
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _showAll = true),
                          child: Text(
                            'Load all 195 countries',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: subtextColor,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
