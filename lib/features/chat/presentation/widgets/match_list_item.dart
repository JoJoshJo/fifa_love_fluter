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

    if (lastMsg == null) {
      previewText = 'Say hello! 👋';
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
                        border: Border.all(
                          color: const Color(0xFF4CB572).withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: ClipOval(
                          child: avatarUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl,
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
                          Text(
                            other['name'] as String? ?? 'Unknown',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600,
                              color: isLight ? const Color(0xFF0D2B1E) : Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            timeStr.toUpperCase(),
                            style: GoogleFonts.spaceMono(
                              fontSize: 9,
                              fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                              color: unread > 0
                                  ? const Color(0xFF4CB572)
                                  : (isLight ? const Color(0xFF9BB3AF) : Colors.white24),
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
                              ? (isLight ? const Color(0xFF0D2B1E).withValues(alpha: 0.8) : Colors.white70)
                              : (isLight ? const Color(0xFF9BB3AF) : Colors.white38),
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
                      color: Color(0xFF4CB572),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 90),
            child: Divider(
              height: 1,
              color: isLight ? const Color(0xFFE5E0D8) : const Color(0xFF1A1A1A),
            ),
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
