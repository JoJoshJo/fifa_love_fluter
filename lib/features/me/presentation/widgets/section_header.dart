import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final bool isEditable;
  const SectionHeader(this.title, {super.key, this.isEditable = false});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final text = isLight ? const Color(0xFF0D2B1E) : const Color(0xFFEBF2EE);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: isLight ? const Color(0xFF135E4B) : const Color(0xFF4CB572),
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          if (isEditable)
            Text(
              "EDIT ALL",
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                color: isLight ? const Color(0xFF135E4B).withValues(alpha: 0.6) : const Color(0xFF4CB572).withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }
}
