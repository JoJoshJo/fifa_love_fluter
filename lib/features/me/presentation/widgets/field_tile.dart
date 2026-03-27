import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FieldTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isMultiLine;

  const FieldTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
    this.isMultiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18,
                  color: const Color(0xFF4CB572).withValues(alpha: 0.7)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.isEmpty ? 'Tap to add' : value,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: value.isEmpty
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: isMultiLine ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: Colors.white.withValues(alpha: 0.20)),
          ],
        ),
      ),
    );
  }
}
