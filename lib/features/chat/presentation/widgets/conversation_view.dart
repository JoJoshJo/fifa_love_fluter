import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fifalove_mobile/core/constants/colors.dart';
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
    if (_messageController.text.trim().isEmpty) return;

    // Guard against null match ID
    final matchId = widget.match['id'] as String?;
    if (matchId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to send — match not found'),
            backgroundColor: Color(0xFFE83535),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final content = _messageController.text.trim();
    final originalText = _messageController.text;
    _messageController.clear();

    try {
      await _repo.sendMessage(
        matchId: matchId,
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
      backgroundColor: Theme.of(context).cardColor,
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
                color: Theme.of(context).dividerColor,
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
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Unmatch?',
            style: GoogleFonts.spaceGrotesk(color: Theme.of(context).textTheme.titleLarge?.color)),
        content: Text('This will remove the match and all messages.',
            style: GoogleFonts.inter(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5))),
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
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        size: 20,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.60)),
                  onPressed: widget.onBack,
                ),
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).primaryColor, width: 1.5),
                    color: Theme.of(context).cardColor,
                  ),
                  child: ClipOval(
                    child: avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(
                                Icons.person,
                                color: Theme.of(context).primaryColor),
                          )
                        : Center(
                            child: Text(
                              (other['name'] as String? ?? '?')[0].toUpperCase(),
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
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
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${_flagEmoji(other['nationality'] as String?)} ${other['nationality'] ?? ''}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.40),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.40)),
                  onPressed: _showOptionsSheet,
                ),
              ],
            ),
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
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
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
                          color: Theme.of(context).primaryColor,
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
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.30)),
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
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
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
                      const SizedBox(height: 60),
                      // Matched profiles avatars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // My Avatar
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).primaryColor, width: 1),
                                  color: Theme.of(context).cardColor,
                                ),
                                child: ClipOval(
                                  child: widget.myProfile['avatar_url'] != null
                                      ? CachedNetworkImage(
                                          imageUrl: widget.myProfile['avatar_url'],
                                          fit: BoxFit.cover,
                                        )
                                      : Center(
                                          child: Text(
                                              (widget.myProfile['name'] as String? ?? 'Me')[0].toUpperCase(),
                                              style: TextStyle(color: Theme.of(context).primaryColor),
                                            ),
                                          ),
                                ),
                              ),
                              // Their Avatar
                              Padding(
                                padding: const EdgeInsets.only(left: 60),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Theme.of(context).primaryColor, width: 1),
                                    color: Theme.of(context).cardColor,
                                  ),
                                  child: ClipOval(
                                    child: avatarUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: avatarUrl,
                                            fit: BoxFit.cover,
                                          )
                                        : Center(
                                            child: Text(
                                              (other['name'] as String? ?? '?')[0].toUpperCase(),
                                              style: TextStyle(color: Theme.of(context).primaryColor),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              // Heart icon last (on top)
                              Positioned(
                                left: 40,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.favorite,
                                      size: 16, color: FifaColors.pink),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You matched! 🎉',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Say something to start\nthe conversation',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.35),
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
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(
                  color: Theme.of(context).dividerColor, width: 1),
            ),
          ),
          padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: GoogleFonts.inter(
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.85),
                        fontSize: 14),
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: GoogleFonts.inter(
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.25),
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: InputBorder.none,
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
                    shape: BoxShape.circle,
                    color: _inputHasText
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).dividerColor.withValues(alpha: 0.05),
                    gradient: _inputHasText
                        ? LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: _inputHasText
                        ? Colors.white
                        : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.20),
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
