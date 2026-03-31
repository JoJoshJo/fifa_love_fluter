import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const allInterests = [
  '⚽ Die-Hard Fan',
  '🍽️ Foodie',
  '🎶 Music',
  '📸 Explorer',
  '🎭 Culture',
  '🎨 Art',
  '📚 History',
  '🏃 Active',
  '🍺 Nightlife',
  '🏖️ Beach',
  '🎮 Gaming',
  '🛍️ Shopping',
];

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
                  ? const Color(0xFF135E4B)
                  : const Color(0xFF152B1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4CB572)
                    : const Color(0xFF1E4A33),
              ),
            ),
            child: Text(
              interest,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isSelected
                    ? const Color(0xFFEBF2EE)
                    : const Color(0xFFEBF2EE).withValues(alpha: 0.4),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
