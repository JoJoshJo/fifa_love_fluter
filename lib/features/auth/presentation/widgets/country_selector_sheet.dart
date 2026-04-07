import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/colors.dart';

class CountrySelectorSheet extends StatefulWidget {
  final List<String> selectedCountries;
  final Function(List<String>) onSelect;

  const CountrySelectorSheet({
    super.key,
    required this.selectedCountries,
    required this.onSelect,
  });

  @override
  State<CountrySelectorSheet> createState() => _CountrySelectorSheetState();
}

class _CountrySelectorSheetState extends State<CountrySelectorSheet> {
  late List<String> _tempSelected;
  String _searchQuery = "";

  final List<String> _allCountries = [
    "Argentina", "Australia", "Belgium", "Brazil", "Cameroon", "Canada", 
    "Costa Rica", "Croatia", "Denmark", "Ecuador", "England", "France", 
    "Germany", "Ghana", "Iran", "Japan", "Mexico", "Morocco", "Netherlands", 
    "Poland", "Portugal", "Qatar", "Saudi Arabia", "Senegal", "Serbia", 
    "South Korea", "Spain", "Switzerland", "Tunisia", "USA", "Uruguay", "Wales",
    "Italy", "Nigeria", "Colombia", "Sweden", "Chile", "Ivory Coast", 
    "Algeria", "Norway", "Scotland", "Ireland", "Turkey", "Egypt", "Peru", 
    "Paraguay", "Ukraine", "Czech Republic", "Austria", "Hungary", "China",
    "India", "South Africa", "New Zealand", "Greece", "Romania", "Bulgaria"
  ]..sort();

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedCountries);
  }

  List<String> get _filteredCountries {
    if (_searchQuery.isEmpty) return _allCountries;
    return _allCountries
        .where((c) => c.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
            child: Row(
              children: [
                Text(
                  "SELECT COUNTRIES",
                  style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: TurfArdorColors.accent,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: "Search nations...",
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: isLight ? const Color(0xFFF2F2F2) : theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Country List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = _tempSelected.contains(country);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _tempSelected.add(country);
                      } else {
                        _tempSelected.remove(country);
                      }
                    });
                  },
                  title: Text(
                    country,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? TurfArdorColors.emeraldSpring : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  activeColor: TurfArdorColors.emeraldSpring,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  controlAffinity: ListTileControlAffinity.trailing,
                );
              },
            ),
          ),

          // Actions
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _tempSelected.clear()),
                  child: Text(
                    "Clear all",
                    style: GoogleFonts.inter(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    widget.onSelect(_tempSelected);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text("Apply Selection"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
