import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/supabase/supabase_config.dart';

class ScoreGauge extends StatelessWidget {
  final int score;
  final double size;
  final Map<String, dynamic>? profile;

  const ScoreGauge({
    super.key,
    required this.score,
    this.size = 64,
    this.profile,
  });

  Color _colorForScore(int s) {
    if (s < 40) return const Color(0xFFE83535);
    if (s < 60) return const Color(0xFFF2C233);
    if (s < 80) return const Color(0xFF4CB572);
    return const Color(0xFFA1D8B5);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: profile != null
          ? () => _showScoreBreakdown(context)
          : null,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _GaugePainter(
                score: score,
                color: _colorForScore(score),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  score.toString(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '%',
                  style: GoogleFonts.spaceMono(
                    fontSize: 8,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showScoreBreakdown(BuildContext context) {
    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (currentUser == null || profile == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1A13),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ScoreBreakdownSheet(
        profile: profile!,
        userId: currentUser.id,
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int score;
  final Color color;

  _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    // Background track
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.white.withValues(alpha: 0.1);
    canvas.drawCircle(center, radius, bgPaint);

    // Score arc
    final scorePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;

    final sweepAngle = (score / 100) * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.score != score || old.color != color;
}

class _ScoreBreakdownSheet extends StatefulWidget {
  final Map<String, dynamic> profile;
  final String userId;

  const _ScoreBreakdownSheet({required this.profile, required this.userId});

  @override
  State<_ScoreBreakdownSheet> createState() => _ScoreBreakdownSheetState();
}

class _ScoreBreakdownSheetState extends State<_ScoreBreakdownSheet> {
  List<Map<String, dynamic>>? _breakdown;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBreakdown();
  }

  Future<void> _fetchBreakdown() async {
    try {
      final result = await SupabaseConfig.client
          .rpc('get_match_score_breakdown', params: {
        'user_id_a': widget.userId,
        'user_id_b': widget.profile['id'],
      }) as List;
      setState(() {
        _breakdown = result.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      // Fallback mock breakdown
      setState(() {
        _breakdown = [
          {'label': 'Shared Interests', 'pts': 25, 'icon': 'favorite'},
          {'label': 'Similar Languages', 'pts': 20, 'icon': 'language'},
          {'label': 'Compatible Countries', 'pts': 15, 'icon': 'public'},
          {'label': 'Team Compatibility', 'pts': 15, 'icon': 'emoji_events'},
          {'label': 'Active Recently', 'pts': 10, 'icon': 'access_time'},
        ];
        _loading = false;
      });
    }
  }

  IconData _iconForKey(String key) {
    switch (key) {
      case 'favorite':
        return Icons.favorite;
      case 'language':
        return Icons.language;
      case 'public':
        return Icons.public;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'WHY THIS SCORE',
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  color: const Color(0xFF4CB572),
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                color: Color(0xFF4CB572),
                strokeWidth: 2,
              ),
            )
          else
            ..._breakdown!.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF135E4B).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _iconForKey(item['icon'] ?? 'favorite'),
                          size: 16,
                          color: const Color(0xFF4CB572),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['label'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2C233).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${item['pts']}',
                          style: GoogleFonts.spaceMono(
                            fontSize: 12,
                            color: const Color(0xFFF2C233),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
