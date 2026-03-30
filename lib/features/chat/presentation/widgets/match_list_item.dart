import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

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

  String _flagEmoji(String? nationality) {
    const flags = {
      'Brazil': '🇧🇷', 'France': '🇫🇷', 'Argentina': '🇦🇷',
      'USA': '🇺🇸', 'England': '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'Germany': '🇩🇪',
      'Spain': '🇪🇸', 'Portugal': '🇵🇹', 'Morocco': '🇲🇦',
      'Japan': '🇯🇵', 'Nigeria': '🇳🇬', 'Mexico': '🇲🇽',
      'Colombia': '🇨🇴', 'Senegal': '🇸🇳', 'Australia': '🇦🇺',
      'South Korea': '🇰🇷', 'Netherlands': '🇳🇱', 'Italy': '🇮🇹',
      'Belgium': '🇧🇪', 'Canada': '🇨🇦',
    };
    return flags[nationality] ?? '🌍';
  }

  @override
  Widget build(BuildContext context) {
    final other = match['other_user'] as Map<String, dynamic>;
    final lastMsg = match['last_message'] as Map<String, dynamic>?;
    final unread = (match['unread_count'] as int?) ?? 0;
    final avatarUrl = other['avatar_url'] as String?;
    final isVerified = (other['is_verified'] as bool?) ?? false;
    final nationality = other['nationality'] as String?;

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

    if (lastMsg == null) {
      previewText = 'Say hello! 👋';
      previewStyle = GoogleFonts.inter(
        fontSize: 13,
        color: const Color(0xFFEBF2EE).withValues(alpha: 0.35),
        fontStyle: FontStyle.italic,
      );
    } else if (lastMsg['sender_id'] == currentUserId) {
      previewText = 'You: ${lastMsg['content']}';
      previewStyle = GoogleFonts.inter(
        fontSize: 13,
        color: const Color(0xFFEBF2EE).withValues(alpha: 0.35),
      );
    } else {
      previewText = lastMsg['content'] as String? ?? '';
      previewStyle = GoogleFonts.inter(
        fontSize: 13,
        color: const Color(0xFFEBF2EE).withValues(alpha: unread > 0 ? 0.70 : 0.35),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1E3D28),
                      ),
                      child: ClipOval(
                        child: avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _fallbackAvatar(
                                    other['name'] as String? ?? '?'),
                              )
                            : _fallbackAvatar(
                                other['name'] as String? ?? '?'),
                      ),
                    ),
                    if (isActive)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CB572),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF080F0C), width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            other['name'] as String? ?? 'Unknown',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEBF2EE),
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 12,
                              color: Color(0xFF4CB572),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            timeStr,
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: unread > 0
                                  ? const Color(0xFF4CB572)
                                  : const Color(0xFFEBF2EE).withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                            previewText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: previewStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Unread badge
                if (unread > 0)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8437A),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unread > 9 ? '9+' : unread.toString(),
                        style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 80),
            child: Divider(
              height: 1,
              color: const Color(0xFF4CB572).withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: const Color(0xFF152B1E),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF4CB572),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
