import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/worldcup_data.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  String _cityFilter = '';
  String _teamFilter = '';

  List<Map<String, dynamic>> get _filtered {
    return matchSchedule.where((m) {
      final cityMatch =
          _cityFilter.isEmpty || m['city'] == _cityFilter;
      final teamMatch = _teamFilter.isEmpty ||
          (m['team_a'] as String)
              .toLowerCase()
              .contains(_teamFilter.toLowerCase()) ||
          (m['team_b'] as String)
              .toLowerCase()
              .contains(_teamFilter.toLowerCase());
      return cityMatch && teamMatch;
    }).toList();
  }

  String _formatDate(String date) {
    final dt = DateTime.tryParse(date);
    if (dt == null) return date;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day}';
  }

  Color _stageColor(String stage) {
    if (stage == 'Final') return const Color(0xFFF2C233);
    return const Color(0xFF4CB572);
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1A13),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final cities = matchSchedule.map((m) => m['city'] as String).toSet().toList();
        return Padding(
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
                title: Text(
                  'All Cities',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                trailing: _cityFilter.isEmpty
                    ? const Icon(Icons.check, color: Color(0xFF4CB572))
                    : null,
                onTap: () {
                  setState(() => _cityFilter = '');
                  Navigator.pop(context);
                },
              ),
              ...cities.map((c) => ListTile(
                    title: Text(c, style: GoogleFonts.inter(color: Colors.white)),
                    trailing: _cityFilter == c
                        ? const Icon(Icons.check, color: Color(0xFF4CB572))
                        : null,
                    onTap: () {
                      setState(() => _cityFilter = c);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      children: [
        // ─── Filter row ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showCityPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF152B1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1E4A33)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: Color(0xFF4CB572)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _cityFilter.isEmpty ? 'All Cities' : _cityFilter,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Icon(Icons.expand_more,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.40)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_cityFilter.isNotEmpty || _teamFilter.isNotEmpty)
                TextButton(
                  onPressed: () =>
                      setState(() { _cityFilter = ''; _teamFilter = ''; }),
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFFE83535)),
                  ),
                ),
            ],
          ),
        ),

        // ─── Match list ───
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No matches found',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.40),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final m = filtered[index];
                    final isFinal = m['stage'] == 'Final';

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1A13),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFinal
                              ? const Color(0xFFF2C233).withValues(alpha: 0.4)
                              : const Color(0xFF1E4A33),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stage label
                          Row(
                            children: [
                              Text(
                                m['group'] as String,
                                style: GoogleFonts.spaceMono(
                                  fontSize: 9,
                                  color: _stageColor(m['stage'] as String),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              if (isFinal) ...[
                                const SizedBox(width: 6),
                                const Text('🏆', style: TextStyle(fontSize: 12)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Teams row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Team A
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(m['flag_a'] as String,
                                        style: const TextStyle(fontSize: 36)),
                                    const SizedBox(height: 4),
                                    Text(
                                      m['team_a'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                              // VS center
                              Column(
                                children: [
                                  Text(
                                    'VS',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Colors.white.withValues(alpha: 0.30),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    m['time'] as String,
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 10,
                                      color: const Color(0xFFF2C233),
                                    ),
                                  ),
                                ],
                              ),

                              // Team B
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(m['flag_b'] as String,
                                        style: const TextStyle(fontSize: 36)),
                                    const SizedBox(height: 4),
                                    Text(
                                      m['team_b'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Divider
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.08),
                              height: 1,
                            ),
                          ),

                          // Venue info
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 12,
                                  color: Colors.white.withValues(alpha: 0.35)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${m['city']} · ${m['stadium']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatDate(m['date'] as String),
                                style: GoogleFonts.spaceMono(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.30),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
