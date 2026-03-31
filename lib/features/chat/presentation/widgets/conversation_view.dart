import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/chat_repository.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/notifications/notification_service.dart';
import 'message_bubble.dart';
import 'typing_indicator.dart';

class ConversationView extends StatefulWidget {
  final Map<String, dynamic> match;
  final String currentUserId;
  final Map<String, dynamic> myProfile;
  final VoidCallback onBack;

  const ConversationView({
    super.key,
    required this.match,
    required this.currentUserId,
    required this.myProfile,
    required this.onBack,
  });

  @override
  State<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatRepository _repo = ChatRepository(SupabaseConfig.client);

  int _lastMessageCount = 0;

  // ignore: prefer_final_fields — mutated by typing presence callbacks
  bool _otherTyping = false;
  bool _showMatchReasons = true;
  bool _inputHasText = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _repo.markAsRead(widget.match['id'] as String, widget.currentUserId);
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _inputHasText) {
        setState(() => _inputHasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final originalText = _messageController.text;
    _messageController.clear();

    try {
      await _repo.sendMessage(
        matchId: widget.match['id'] as String,
        senderId: widget.currentUserId,
        content: content,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      // Restore text if failed
      _messageController.text = originalText;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString().split(':').last.trim()}'),
            backgroundColor: const Color(0xFFE83535),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _shouldShowTime(List<Map<String, dynamic>> messages, int index) {
    if (index == messages.length - 1) return true;
    final curr = DateTime.tryParse(messages[index]['created_at'] as String? ?? '');
    final next = DateTime.tryParse(messages[index + 1]['created_at'] as String? ?? '');
    if (curr == null || next == null) return false;
    return next.difference(curr).inMinutes > 5;
  }

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

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1A13),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined,
                  color: Color(0xFFE8437A)),
              title: Text('Unmatch',
                  style: GoogleFonts.inter(
                      color: const Color(0xFFE8437A),
                      fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _confirmUnmatch();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Color(0xFFE8437A)),
              title: Text('Block & Report',
                  style: GoogleFonts.inter(
                      color: const Color(0xFFE8437A),
                      fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmUnmatch() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D1A13),
        title: Text('Unmatch?',
            style: GoogleFonts.spaceGrotesk(color: Colors.white)),
        content: Text('This will remove the match and all messages.',
            style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _repo.unmatch(widget.match['id'] as String);
              widget.onBack();
            },
            child: Text('Unmatch',
                style: GoogleFonts.inter(color: const Color(0xFFE8437A))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final other = widget.match['other_user'] as Map<String, dynamic>;
    final avatarUrl = other['avatar_url'] as String?;
    final matchAge = DateTime.now().difference(
        DateTime.parse(widget.match['created_at'] as String));
    final reasons = _repo.getMatchReasons(other, widget.myProfile);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        // ─── Header bar ───
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1A13),
            border: Border(
              bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08), width: 1),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.70)),
                onPressed: widget.onBack,
              ),
              // Avatar
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFF4CB572), width: 1.5),
                  ),
                  color: Color(0xFF1E3D28),
                ),
                child: ClipOval(
                  child: avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Color(0xFF4CB572)),
                        )
                      : Center(
                          child: Text(
                            (other['name'] as String? ?? '?')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                                color: Color(0xFF4CB572),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      other['name'] as String? ?? 'Match',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_flagEmoji(other['nationality'] as String?)} ${other['nationality'] ?? ''}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_vert,
                    color: Colors.white.withValues(alpha: 0.50)),
                onPressed: _showOptionsSheet,
              ),
            ],
          ),
        ),

        // ─── Why you matched card ───
        if (_showMatchReasons &&
            matchAge.inHours < 48 &&
            reasons.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF135E4B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4CB572).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚡ WHY YOU MATCHED',
                        style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          color: const Color(0xFF4CB572),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...reasons.map((r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Text(
                              '· $r',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.30)),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      setState(() => _showMatchReasons = false),
                ),
              ],
            ),
          ),

        // ─── Messages list ───
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _repo.messagesStream(widget.match['id'] as String),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CB572),
                    strokeWidth: 2,
                  ),
                );
              }

              final messages = snapshot.data ?? [];

              if (messages.isNotEmpty && messages.length > _lastMessageCount) {
                 final newMsg = messages.last;
                 if (newMsg['sender_id'] != widget.currentUserId) {
                     final other = widget.match['other_user'] as Map<String, dynamic>;
                     NotificationService().showMessageNotification(
                         senderName: other['name'] ?? 'Match',
                         message: newMsg['content'] as String,
                         matchId: widget.match['id'] as String,
                     );
                 }
                 _lastMessageCount = messages.length;
              }

              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Say hello! 👋',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.40),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You matched with ${other['name'] ?? 'them'}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Auto-scroll when new messages arrive
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent);
                }
              });

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                itemCount: messages.length + (_otherTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_otherTyping && index == messages.length) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: TypingIndicator(),
                    );
                  }
                  final msg = messages[index];
                  final isMe =
                      msg['sender_id'] == widget.currentUserId;
                  final showTime = _shouldShowTime(messages, index);
                  return MessageBubble(
                    message: msg,
                    isMe: isMe,
                    showTime: showTime,
                  );
                },
              );
            },
          ),
        ),

        // ─── Input bar ───
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1A13),
            border: Border(
              top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08), width: 1),
            ),
          ),
          padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.30),
                      fontSize: 14,
                    ),
                    fillColor: const Color(0xFF152B1E),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                          color: Color(0xFF4CB572), width: 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _inputHasText
                        ? const Color(0xFF135E4B)
                        : const Color(0xFF152B1E),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: _inputHasText
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
