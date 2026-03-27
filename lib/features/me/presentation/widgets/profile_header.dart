import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onEditPhoto;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEditPhoto,
  });

  String _flagEmoji(String? nationality) {
    const flags = {
      'Brazil': '🇧🇷', 'France': '🇫🇷', 'Argentina': '🇦🇷',
      'USA': '🇺🇸', 'England': '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'Germany': '🇩🇪',
      'Spain': '🇪🇸', 'Portugal': '🇵🇹', 'Morocco': '🇲🇦',
      'Japan': '🇯🇵', 'Nigeria': '🇳🇬', 'Mexico': '🇲🇽',
      'Colombia': '🇨🇴', 'Senegal': '🇸🇳', 'Australia': '🇦🇺',
      'South Korea': '🇰🇷', 'Netherlands': '🇳🇱', 'Italy': '🇮🇹',
    };
    return flags[nationality] ?? '🌍';
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile['avatar_url'] as String?;
    final name = profile['name'] as String? ?? 'Your Name';
    final nationality = profile['nationality'] as String?;
    final team = profile['team_supported'] as String?;
    final isVerified = profile['is_verified'] == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          // Avatar with edit button
          Stack(
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF4CB572), width: 2.5),
                ),
                child: ClipOval(
                  child: avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          width: 90, height: 90,
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF152B1E),
                            child: const Icon(Icons.person,
                                size: 40, color: Color(0xFF4CB572)),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF152B1E),
                          child: const Icon(Icons.person,
                              size: 40, color: Color(0xFF4CB572)),
                        ),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: onEditPhoto,
                  child: Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CB572),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 15, color: Color(0xFF080F0C)),
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (nationality != null) ...[
                      Text(
                        '${_flagEmoji(nationality)} $nationality',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.60),
                        ),
                      ),
                    ],
                    if (team != null) ...[
                      Text(' · ',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.30))),
                      Flexible(
                        child: Text(
                          team,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? const Color(0xFF135E4B).withValues(alpha: 0.4)
                        : const Color(0xFF152B1E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isVerified
                          ? const Color(0xFF4CB572)
                          : const Color(0xFF1E4A33),
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
                            : Colors.white.withValues(alpha: 0.25),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVerified ? 'ID Verified' : 'Not Verified',
                        style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          color: isVerified
                              ? const Color(0xFF4CB572)
                              : Colors.white.withValues(alpha: 0.25),
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
