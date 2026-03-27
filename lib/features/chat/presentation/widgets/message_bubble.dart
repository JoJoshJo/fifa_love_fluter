import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool showTime;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showTime,
  });

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final content = message['content'] as String? ?? '';
    final readAt = message['read_at'] as String?;

    final bubbleRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // The bubble
              Container(
                constraints: BoxConstraints(maxWidth: screenWidth * 0.72),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isMe ? const Color(0xFF135E4B) : const Color(0xFF1E3D28),
                  borderRadius: bubbleRadius,
                ),
                child: Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.90),
                    height: 1.4,
                  ),
                ),
              ),

              // Timestamp
              if (showTime)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    _formatTime(message['created_at'] as String?),
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),

              // Read receipt (sent/read indicator)
              if (isMe)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.done_all,
                    size: 12,
                    color: readAt != null
                        ? const Color(0xFF4CB572)
                        : Colors.white.withValues(alpha: 0.30),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
