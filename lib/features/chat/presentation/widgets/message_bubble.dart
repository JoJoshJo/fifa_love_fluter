import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fifalove_mobile/core/constants/colors.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool showTime;
  final String? status; // 'sent', 'read', or null
  final bool showStatus;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showTime,
    this.status,
    this.showStatus = false,
  });

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatTimeReadable(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '$hour:$m $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(message['created_at'] as String?);
    final readableTime = _formatTimeReadable(message['created_at'] as String?);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showTime)
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 16),
              child: Center(
                child: Text(
                  timeStr,
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: isLight ? FifaColors.mutedTextLight : Colors.white10,
                  ),
                ),
              ),
            ),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(
                    isMe ? (1.0 - value) * 30 : (value - 1.0) * 30,
                    0,
                  ),
                  child: child,
                ),
              );
            },
            child: Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: isMe
                          ? FifaColors.accent
                          : (isLight ? FifaColors.white : FifaColors.darkCard),
                      borderRadius: isMe
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(4),
                            )
                          : const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(20),
                            ),
                      border: isMe
                          ? null
                          : (isLight ? Border.all(
                              color: FifaColors.lightBorder,
                              width: 1,
                            ) : null),
                      boxShadow: isLight && !isMe
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              )
                            ]
                          : null,
                      image: isMe ? const DecorationImage(
                        image: AssetImage('assets/images/bubbles_pattern.png'),
                        opacity: 0.05,
                        fit: BoxFit.cover,
                      ) : null,
                    ),
                    child: Text(
                      message['content'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.5,
                        color: isMe
                            ? Colors.white
                            : (isLight ? FifaColors.textPrimaryLight : Colors.white70),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe && showStatus)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    readableTime,
                    style: GoogleFonts.spaceMono(
                      fontSize: 8,
                      color: isLight ? const Color(0xFF9BB3AF) : Colors.white24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    status == 'read' ? LucideIcons.checkCheck : LucideIcons.checkCheck,
                    size: 12,
                    color: status == 'read'
                        ? const Color(0xFF4CB572)
                        : (isLight ? const Color(0xFF9BB3AF) : Colors.white24),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
