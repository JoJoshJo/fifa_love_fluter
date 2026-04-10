import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onEditPhoto;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEditPhoto,
  });

  dynamic _flagEmoji(String? nationality) {
    const flags = {
      'Brazil': '🇧🇷', 'France': '🇫🇷', 'Argentina': '🇦🇷',
      'USA': '🇺🇸', 'England': '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'Germany': '🇩🇪',
      'Spain': '🇪🇸', 'Portugal': '🇵🇹', 'Morocco': '🇲🇦',
      'Japan': '🇯🇵', 'Nigeria': '🇳🇬', 'Mexico': '🇲🇽',
      'Colombia': '🇨🇴', 'Senegal': '🇸🇳', 'Australia': '🇦🇺',
      'South Korea': '🇰🇷', 'Netherlands': '🇳🇱', 'Italy': '🇮🇹',
    };
    return flags[nationality] ?? LucideIcons.globe;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? const Color(0xFFF5F0E8) : const Color(0xFF080F0C);
    final text = isLight ? const Color(0xFF0D2B1E) : const Color(0xFFEBF2EE);
    final muted = isLight ? const Color(0xFF6B9E8A) : const Color(0xFF9BB3AF);
    final border = isLight ? const Color(0xFFE8DDD0) : const Color(0xFF1E4A33);

    final avatarUrl = profile['avatar_url'] as String?;
    final name = profile['name'] as String? ?? 'Your Name';
    final nationality = profile['nationality'] as String?;
    final team = profile['team_supported'] as String?;
    final isVerified = profile['is_verified'] == true;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 24, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with camera button
          Stack(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF4CB572), width: 2),
                ),
                child: ClipOval(
                  child: avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          width: 80, height: 80,
                          errorWidget: (_, __, ___) => Container(
                            color: isLight ? Colors.black12 : const Color(0xFF152B1E),
                            child: const Center(
                              child: Icon(Icons.person_outline,
                                  size: 36, color: Color(0xFF4CB572)),
                            ),
                          ),
                        )
                      : Container(
                          color: isLight ? Colors.black12 : const Color(0xFF152B1E),
                          child: const Center(
                            child: Icon(Icons.person_outline,
                                size: 36, color: Color(0xFF4CB572)),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: onEditPhoto,
                  child: Container(
                    width: 26, height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CB572),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.camera_alt,
                          size: 14, color: isLight ? Colors.white : const Color(0xFF080F0C)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: text,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (nationality != null && nationality.isNotEmpty) ...[
                      Builder(builder: (context) {
                        final flag = _flagEmoji(nationality);
                        return flag is IconData
                            ? Icon(flag, size: 14, color: muted)
                            : Text(flag, style: const TextStyle(fontSize: 14));
                      }),
                      const SizedBox(width: 4),
                      Text(
                        nationality,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: muted,
                        ),
                      ),
                    ],
                    if (team != null && team.isNotEmpty) ...[
                      Text(' · ',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: text.withValues(alpha: 0.3))),
                      Flexible(
                        child: Text(
                          team,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: text.withValues(alpha: 0.45),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? const Color(0xFF135E4B)
                        : (isLight ? Colors.black.withValues(alpha: 0.05) : const Color(0xFF152B1E)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isVerified
                          ? const Color(0xFF4CB572)
                          : border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified
                            ? Icons.verified
                            : Icons.verified_outlined,
                        size: 12,
                        color: isVerified
                            ? const Color(0xFF4CB572)
                            : text.withValues(alpha: 0.25),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVerified ? 'ID VERIFIED' : 'NOT VERIFIED',
                        style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          letterSpacing: 1,
                          color: isVerified
                              ? const Color(0xFF4CB572)
                              : text.withValues(alpha: 0.25),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
