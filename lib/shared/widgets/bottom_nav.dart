import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? const Color(0xFFF5F0E8) : const Color(0xFF080F0C);
    
    return Container(
      height: 64 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: bgColor,
      ),
      child: Stack(
        children: [
          // Subtle Active Indicator Dot
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            left: (MediaQuery.of(context).size.width / 4) * widget.currentIndex + (MediaQuery.of(context).size.width / 8) - 2,
            bottom: 8,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF4CB572),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              _AnimatedNavItem(
                index: 0,
                currentIndex: widget.currentIndex,
                icon: LucideIcons.home,
                label: 'DISCOVER',
                onTap: () => widget.onTap(0),
              ),
              _AnimatedNavItem(
                index: 1,
                currentIndex: widget.currentIndex,
                icon: LucideIcons.messageCircle,
                label: 'CHAT',
                onTap: () => widget.onTap(1),
                showBadge: true,
                unreadStream: _unreadCountStream,
              ),
              _AnimatedNavItem(
                index: 2,
                currentIndex: widget.currentIndex,
                icon: LucideIcons.trophy,
                label: 'WORLD CUP',
                onTap: () => widget.onTap(2),
              ),
              _AnimatedNavItem(
                index: 3,
                currentIndex: widget.currentIndex,
                icon: LucideIcons.user,
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
  final String label;
  final VoidCallback onTap;
  final bool showBadge;
  final Stream<int>? unreadStream;

  const _AnimatedNavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final color = isActive 
      ? const Color(0xFF135E4B) 
      : (isLight ? const Color(0xFF9BB3AF) : Colors.white.withValues(alpha: 0.2));

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
                    widget.icon, 
                    color: color, 
                    size: 22,
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
