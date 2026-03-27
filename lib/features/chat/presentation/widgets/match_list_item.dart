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
    if (lastMsg == null) {
      previewText = 'Say hello! 👋';
      previewStyle = GoogleFonts.inter(
        fontSize: 13,
        color: Colors.white.withValues(alpha: 0.35),
        fontStyle: FontStyle.italic,
      );
    } else if (lastMsg['sender_id'] == currentUserId) {
      previewText = 'You: ${lastMsg['content']}';
      previewStyle = GoogleFonts.inter(
        fontSize: 13,
        color: Colors.white.withValues(alpha: 0.40),
      );
    } else {
      previewText = lastMsg['content'] as String? ?? '';
      previewStyle = GoogleFonts.inter(
        fontSize: 13,
        color: Colors.white.withValues(alpha: unread > 0 ? 0.80 : 0.45),
        fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 80,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: unread > 0
                                  ? const Color(0xFF4CB572)
                                  : Colors.transparent,
                              width: 2,
                            ),
                            color: const Color(0xFF1E3D28),
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
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1A13),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF0D1A13), width: 1),
                            ),
                            child: Center(
                              child: Text(
                                _flagEmoji(nationality),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Name + preview
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
                                  color: Colors.white,
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

                    // Time + badge
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeStr,
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.30),
                          ),
                        ),
                        const SizedBox(height: 6),
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
                          )
                        else
                          const SizedBox(width: 20, height: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06),
              indent: 72,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackAvatar(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: const Color(0xFF1E4A33),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF4CB572),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
