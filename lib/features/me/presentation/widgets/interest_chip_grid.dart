import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

const allInterests = [
  'Die-Hard Fan',
  'Foodie',
  'Music',
  'Explorer',
  'Culture',
  'Art',
  'History',
  'Active',
  'Nightlife',
  'Beach',
  'Gaming',
  'Shopping',
];

IconData _getInterestIcon(String interest) {
  switch (interest) {
    case 'Die-Hard Fan': return LucideIcons.trophy;
    case 'Foodie': return LucideIcons.utensils;
    case 'Music': return LucideIcons.music;
    case 'Explorer': return LucideIcons.camera;
    case 'Culture': return LucideIcons.clapperboard;
    case 'Art': return LucideIcons.palette;
    case 'History': return LucideIcons.bookOpen;
    case 'Active': return LucideIcons.footprints;
    case 'Nightlife': return LucideIcons.beer;
    case 'Beach': return LucideIcons.palmtree;
    case 'Gaming': return LucideIcons.gamepad2;
    case 'Shopping': return LucideIcons.shoppingBag;
    default: return LucideIcons.star;
  }
}

class InterestChipGrid extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const InterestChipGrid({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allInterests.map((interest) {
        final isSelected = selected.contains(interest);
        return GestureDetector(
          onTap: () {
            final updated = List<String>.from(selected);
            if (isSelected) {
              updated.remove(interest);
            } else {
              updated.add(interest);
            }
            onChanged(updated);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (Theme.of(context).brightness == Brightness.light ? const Color(0xFFFCE4EC) : const Color(0xFF880E4F))
                  : (Theme.of(context).brightness == Brightness.light ? const Color(0xFFF5F0E8) : const Color(0xFF152B1E)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFE8437A)
                    : (Theme.of(context).brightness == Brightness.light ? const Color(0xFFE8DDD0) : Colors.white.withValues(alpha: 0.12)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getInterestIcon(interest),
                  size: 16,
                  color: isSelected
                      ? (Theme.of(context).brightness == Brightness.light ? const Color(0xFF880E4F) : Colors.white)
                      : (Theme.of(context).brightness == Brightness.light ? const Color(0xFF3D3025) : Colors.white.withValues(alpha: 0.4)),
                ),
                const SizedBox(width: 8),
                Text(
                  interest.toUpperCase(),
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? (Theme.of(context).brightness == Brightness.light ? const Color(0xFF880E4F) : Colors.white)
                        : (Theme.of(context).brightness == Brightness.light ? const Color(0xFF3D3025) : Colors.white.withValues(alpha: 0.4)),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
