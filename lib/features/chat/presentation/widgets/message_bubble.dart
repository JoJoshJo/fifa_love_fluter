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
    final timeStr = _formatTime(message['created_at'] as String?);
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
                    color: isLight ? const Color(0xFF9BB3AF) : Colors.white10,
                  ),
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF135E4B)
                        : (isLight ? Colors.white : const Color(0xFF1D2F28)),
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
                        : Border.all(
                            color: isLight
                                ? const Color(0xFFE8DDD0)
                                : const Color(0xFF1E4A33),
                            width: 1,
                          ),
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
                          : (isLight ? const Color(0xFF0D2B1E) : Colors.white70),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
