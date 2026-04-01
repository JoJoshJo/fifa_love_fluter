import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
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
    final isMine = isMe;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Transform.scale(
                scale: 0.8 + (0.2 * value),
                alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                child: child,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  isMine ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                if (isMine) const Spacer(),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMine
                          ? FifaColors.emeraldForest
                          : Theme.of(context).cardColor,
                      borderRadius: isMine
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(4),
                            )
                          : const BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(18),
                            ),
                      border: isMine
                          ? null
                          : Border.all(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                    ),
                    child: Text(
                      message['content'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isMine
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                if (!isMine) const Spacer(),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMine) const SizedBox(width: 40),
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.35),
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message['read_at'] != null ? Icons.done_all : Icons.done,
                    size: 12,
                    color: message['read_at'] != null
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.35),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
