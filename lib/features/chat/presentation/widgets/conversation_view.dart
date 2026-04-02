import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fifalove_mobile/core/constants/colors.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

  final bool _otherTyping = false;
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
              leading: const Icon(LucideIcons.userMinus,
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
              leading: const Icon(LucideIcons.ban, color: Color(0xFFE8437A)),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundColor = isLight
        ? const Color(0xFFF5F0E8)
        : const Color(0xFF080F0C);
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final matchAge = DateTime.now().difference(DateTime.parse(widget.match['created_at'] as String));
    final reasons = (widget.match['match_reasons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          // ─── Header bar ───
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: isLight ? const Border(
                bottom: BorderSide(
                  color: FifaColors.lightBorder,
                  width: 1,
                ),
              ) : null,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    LucideIcons.chevronLeft,
                    size: 24,
                    color: isLight ? const Color(0xFF0D2B1E) : Colors.white70,
                  ),
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 4),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: avatarUrl != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: isLight ? Colors.white : Colors.white10,
                  ),
                  child: avatarUrl == null
                      ? Center(
                          child: Text(
                            (other['name'] as String? ?? '?')[0].toUpperCase(),
                            style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFF4CB572),
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        other['name'] as String? ?? 'Match',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isLight ? const Color(0xFF0D2B1E) : Colors.white,
                        ),
                      ),
                      Text(
                        'Match since ${_timeAgo(widget.match['created_at'] as String?)}',
                        style: GoogleFonts.spaceMono(
                          fontSize: 8,
                          color: const Color(0xFF4CB572),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    LucideIcons.moreVertical,
                    color: isLight ? const Color(0xFF9BB3AF) : Colors.white24,
                  ),
                  onPressed: _showOptionsSheet,
                ),
              ],
            ),
          ),

          if (_showMatchReasons && matchAge.inHours < 48 && reasons.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CB572).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: isLight ? Border.all(
                  color: const Color(0xFF4CB572).withValues(alpha: 0.25),
                ) : null,
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
                                  color: isLight ? const Color(0xFF0D2B1E).withValues(alpha: 0.65) : Colors.white70,
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x,
                        size: 16,
                        color: isLight ? const Color(0xFF9BB3AF) : Colors.white24),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _showMatchReasons = false),
                  ),
                ],
              ),
            ),

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
                    final otherName = other['name'] ?? 'Match';
                    NotificationService().showMessageNotification(
                      senderName: otherName,
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
                        const SizedBox(height: 40),
                        SizedBox(
                          height: 90,
                          width: 140,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                left: 0,
                                child: _avatarCircle(
                                    widget.myProfile['avatar_url'],
                                    widget.myProfile['name']),
                              ),
                              Positioned(
                                right: 0,
                                child: _avatarCircle(avatarUrl, other['name']),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF135E4B),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(LucideIcons.heart,
                                    size: 16, color: Color(0xFFE8437A)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          "It's a Match!",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: isLight ? const Color(0xFF0D2B1E) : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You and ${other['name']?.split(' ')?.first} both liked\neach other. Start the conversation!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            height: 1.5,
                            color: isLight ? const Color(0xFF9BB3AF) : Colors.white.withValues(alpha: 0.34),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'STUCK? TRY A WORLD CUP TRIVIA QUESTION!',
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            color: const Color(0xFF4CB572),
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

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
                    final isMe = msg['sender_id'] == widget.currentUserId;
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
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: isLight ? const Border(
                top: BorderSide(
                    color: Color(0xFFE8DDD0),
                    width: 1),
              ) : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: isLight ? Border.all(
                        color: const Color(0xFFE8DDD0),
                      ) : null,
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isLight ? const Color(0xFF0D2B1E) : Colors.white,
                      ),
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Write to ${other['name']?.split(' ')?.first}...',
                        hintStyle: GoogleFonts.playfairDisplay(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: isLight ? FifaColors.mutedTextLight : Colors.white24,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_inputHasText)
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF135E4B),
                            Color(0xFF4CB572),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                        child: const Icon(
                          LucideIcons.send,
                          size: 20,
                          color: Colors.white,
                        ),
                    ),
                  )
                else
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: isLight ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                      child: Icon(
                        LucideIcons.mic,
                        size: 22,
                        color: isLight ? const Color(0xFF9BB3AF) : Colors.white24,
                      ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarCircle(String? url, String? name) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4CB572), width: 1.5),
        image: url != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(url), fit: BoxFit.cover)
            : null,
        color: Colors.white10,
      ),
      child: url == null
          ? Center(
              child: Text(
                (name ?? '?')[0].toUpperCase(),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4CB572),
                ),
              ),
            )
          : null,
    );
  }

  String _timeAgo(String? isoString) {
    if (isoString == null) return '';
    final time = DateTime.tryParse(isoString);
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[time.weekday - 1];
  }
}
