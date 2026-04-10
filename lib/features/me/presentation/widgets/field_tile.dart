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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final text = isLight ? const Color(0xFF0D2B1E) : const Color(0xFFEBF2EE);
    final border = isLight ? const Color(0xFFE8DDD0) : const Color(0xFF1E4A33);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18,
                  color: const Color(0xFF4CB572).withValues(alpha: 0.6)),
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
                      color: text.withValues(alpha: 0.35),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value.isEmpty ? 'Tap to add' : value,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: value.isEmpty
                          ? text.withValues(alpha: 0.25)
                          : text.withValues(alpha: 0.85),
                    ),
                    maxLines: isMultiLine ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: text.withValues(alpha: 0.20)),
          ],
        ),
      ),
    );
  }
}
