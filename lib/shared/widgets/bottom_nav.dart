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
  Stream<int>? _unreadCountStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId != null) {
        _unreadCountStream = SupabaseConfig.client
            .from('messages')
            .stream(primaryKey: ['id'])
            .map((list) => list.where((m) => m['sender_id'] != userId && m['read_at'] == null).length);
      }
    } catch (_) {
      _unreadCountStream = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final theme = Theme.of(context);
    
    return Container(
      height: 64 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Moving Indicator Line
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            left: (MediaQuery.of(context).size.width / 4) * widget.currentIndex + (MediaQuery.of(context).size.width / 8) - 12,
            top: 0,
            child: Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _AnimatedNavItem(
                index: 0,
                currentIndex: widget.currentIndex,
                icon: Icons.local_fire_department_outlined,
                activeIcon: Icons.local_fire_department,
                label: 'DISCOVER',
                onTap: () => widget.onTap(0),
              ),
              _AnimatedNavItem(
                index: 1,
                currentIndex: widget.currentIndex,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'CHAT',
                onTap: () => widget.onTap(1),
                showBadge: true,
                unreadStream: _unreadCountStream,
              ),
              _AnimatedNavItem(
                index: 2,
                currentIndex: widget.currentIndex,
                icon: Icons.emoji_events_outlined,
                activeIcon: Icons.emoji_events,
                label: 'WORLD CUP',
                onTap: () => widget.onTap(2),
              ),
              _AnimatedNavItem(
                index: 3,
                currentIndex: widget.currentIndex,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'ME',
                onTap: () => widget.onTap(3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedNavItem extends StatefulWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
  final bool showBadge;
  final Stream<int>? unreadStream;

  const _AnimatedNavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.showBadge = false,
    this.unreadStream,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_AnimatedNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex == widget.index && oldWidget.currentIndex != widget.index) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.currentIndex == widget.index;
    final theme = Theme.of(context);
    final color = isActive ? theme.primaryColor : theme.hintColor.withValues(alpha: 0.4);

    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isActive ? widget.activeIcon : widget.icon, 
                    color: color, 
                    size: 24,
                  ),
                  if (widget.showBadge)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: StreamBuilder<int>(
                        stream: widget.unreadStream,
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          if (count == 0) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8437A), 
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16, 
                              minHeight: 16,
                            ),
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: const TextStyle(
                                color: Colors.white, 
                                fontSize: 8, 
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
