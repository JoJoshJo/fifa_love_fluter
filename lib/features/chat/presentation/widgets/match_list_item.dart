import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/colors.dart';
import 'package:fifalove_mobile/core/utils/url_helper.dart';



class MatchListItem extends StatelessWidget {
  final Map<String, dynamic> match;
  final String currentUserId;
  final VoidCallback onTap;

  const MatchListItem({
    super.key,
    required this.match,
    required this.currentUserId,
    required this.onTap,
  });

  String _timeAgo(String? isoString) {
    if (isoString == null) return '';
    final time = DateTime.tryParse(isoString);
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[time.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final other = match['other_user'] as Map<String, dynamic>;
    final lastMsg = match['last_message'] as Map<String, dynamic>?;
    final unread = (match['unread_count'] as int?) ?? 0;
    final avatarUrl = other['avatar_url'] as String?;
    final timeStr = lastMsg != null
        ? _timeAgo(lastMsg['created_at'] as String?)
        : _timeAgo(match['created_at'] as String?);

    String previewText;
    TextStyle previewStyle;
    bool isActive = false;
    if (other['last_active'] != null) {
      final lastActive = DateTime.tryParse(other['last_active'] as String);
      if (lastActive != null && DateTime.now().difference(lastActive).inMinutes <= 30) {
        isActive = true;
      }
    }

    // New Match / Verified Glow Logic
    final isVerified = other['is_verified'] as bool? ?? false;
    final createdAt = match['created_at'] as String?;
    bool isRecent = false;
    if (createdAt != null) {
      final createdTime = DateTime.tryParse(createdAt);
      if (createdTime != null && DateTime.now().difference(createdTime).inHours < 24) {
        isRecent = true;
      }
    }
    final showGlow = isVerified || isRecent;

    if (lastMsg == null) {
      previewText = 'Say hello!';
      previewStyle = GoogleFonts.inter(
        fontSize: 13,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.35),
        fontStyle: FontStyle.italic,
      );
    } else if (lastMsg['sender_id'] == currentUserId) {
      previewText = 'You: ${lastMsg['content']}';
      previewStyle = GoogleFonts.inter(
        fontSize: 13,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.35),
      );
    } else {
      previewText = lastMsg['content'] as String? ?? '';
      previewStyle = GoogleFonts.inter(
        fontSize: 13,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: unread > 0 ? 0.70 : 0.35),
      );
    }

    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: showGlow ? [
                          BoxShadow(
                            color: FifaColors.pink.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ] : null,
                        border: showGlow 
                          ? Border.all(
                              color: FifaColors.pink.withValues(alpha: 0.6),
                              width: 2,
                            )
                          : isLight ? Border.all(
                              color: const Color(0xFF4CB572).withValues(alpha: 0.2),
                              width: 1.5,
                            ) : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: ClipOval(
                          child: avatarUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: UrlHelper.resolveImageUrl(avatarUrl),
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => _fallbackAvatar(
                                      context, other['name'] as String? ?? '?'),
                                )
                              : _fallbackAvatar(
                                  context, other['name'] as String? ?? '?'),
                        ),
                      ),
                    ),
                    if (isActive)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CB572),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isLight
                                    ? const Color(0xFFF5F0E8)
                                    : const Color(0xFF080F0C),
                                width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                other['name'] as String? ?? 'Unknown',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 17,
                                  fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                  color: isLight ? FifaColors.textPrimaryLight : Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (other['is_verified'] == true) ...[
                                const SizedBox(width: 4),
                                const Icon(LucideIcons.badgeCheck, size: 14, color: Color(0xFF4CB572)),
                              ],
                              const SizedBox(width: 8),
                              // Match score badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (match['match_score'] as num? ?? 0) >= 85 
                                    ? const Color(0xFFF2C233) 
                                    : FifaColors.champagneGlow,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${match['match_score'] ?? 80}%',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: (match['match_score'] as num? ?? 0) >= 85
                                      ? const Color(0xFF5A4500)
                                      : const Color(0xFF5A4500).withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            timeStr.toUpperCase(),
                            style: GoogleFonts.spaceMono(
                              fontSize: 9,
                              fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                              color: unread > 0
                                  ? FifaColors.accent
                                  : (isLight ? FifaColors.mutedTextLight : Colors.white24),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        previewText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: previewStyle.copyWith(
                          fontSize: 13,
                          color: unread > 0
                              ? (isLight ? FifaColors.textPrimaryLight.withValues(alpha: 0.8) : Colors.white70)
                              : (isLight ? FifaColors.mutedTextLight : Colors.white38),
                        ),
                      ),
                    ],
                  ),
                ),

                // Unread dot
                if (unread > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: FifaColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 90),
            child: isLight ? const Divider(
              height: 1,
              color: Color(0xFFE5E0D8),
            ) : null,
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar(BuildContext context, String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      color: isLight ? Colors.white : Colors.white10,
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF4CB572),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
