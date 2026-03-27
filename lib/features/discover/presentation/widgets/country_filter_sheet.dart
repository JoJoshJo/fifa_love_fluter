import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D1A13),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'MATCH WITH FANS FROM',
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: const Color(0xFF4CB572),
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
                            fontSize: 13, color: const Color(0xFF4CB572)),
                      ),
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextFormField(
                  onChanged: (v) => setState(() => _search = v),
                  style: GoogleFonts.inter(
                      fontSize: 14, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search countries…',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.4)),
                    prefixIcon: const Icon(Icons.search,
                        color: Color(0xFF4CB572), size: 18),
                    filled: true,
                    fillColor: const Color(0xFF152B1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
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
                              color: isSelected
                                  ? const Color(0xFF135E4B)
                                  : const Color(0xFF152B1E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4CB572)
                                    : Colors.white.withValues(alpha: 0.12),
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
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white
                                            .withValues(alpha: 0.7),
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
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
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
