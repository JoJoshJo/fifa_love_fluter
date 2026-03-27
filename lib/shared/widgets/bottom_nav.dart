import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/supabase/supabase_config.dart';

class FifaBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FifaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FifaBottomNav> createState() => _FifaBottomNavState();
}

class _FifaBottomNavState extends State<FifaBottomNav> {
  Stream<List<Map<String, dynamic>>>? _unreadMessagesStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    try {
      if (SupabaseConfig.client.auth.currentUser != null) {
        _unreadMessagesStream = SupabaseConfig.client
            .from('messages')
            .stream(primaryKey: ['id']);
      }
    } catch (_) {
      // Fallback gracefully if database or table is missing
      _unreadMessagesStream = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      height: 64 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A13),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.local_fire_department_outlined,
                activeIcon: Icons.local_fire_department,
                label: 'DISCOVER',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'CHAT',
                showBadge: true,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.emoji_events_outlined,
                activeIcon: Icons.emoji_events,
                label: 'WORLD CUP',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'ME',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool showBadge = false,
  }) {
    final isActive = widget.currentIndex == index;
    const activeColor = Color(0xFF4CB572);
    final inactiveColor = Colors.white.withOpacity(0.28);
    final color = isActive ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTap(index),
        child: AnimatedScale(
          scale: isActive ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Indicator Line
              if (isActive)
                Positioned(
                  top: 0,
                  child: Container(
                    width: 24,
                    height: 3,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
                
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8), // Pad top for indicator
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isActive ? activeIcon : icon,
                        size: 24,
                        color: color,
                      ),
                      if (showBadge)
                        Positioned(
                          top: -4,
                          right: -8,
                          child: _buildBadge(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      letterSpacing: 1,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    if (_unreadMessagesStream == null) return const SizedBox.shrink();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _unreadMessagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
        final unreadMessages = snapshot.data!.where((msg) {
          return msg['sender_id'] != currentUserId && msg['read_at'] == null;
        }).toList();

        final count = unreadMessages.length;
        if (count == 0) return const SizedBox.shrink();

        return Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFFE8437A),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count > 9 ? '9+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
