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

  Widget _buildQuickLinks() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'EXPLORE MORE',
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                color: const Color(0xFF4CB572),
                letterSpacing: 2,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 80,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1A13),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CB572).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number, size: 24, color: Color(0xFF4CB572)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'FAN ZONE',
                              style: GoogleFonts.spaceMono(
                                fontSize: 8,
                                color: const Color(0xFF4CB572),
                              ),
                            ),
                            Text(
                              'Ticket Marketplace',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 80,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1A13),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CB572).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.restaurant, size: 24, color: Color(0xFF4CB572)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'LOCAL EATS',
                              style: GoogleFonts.spaceMono(
                                fontSize: 8,
                                color: const Color(0xFF4CB572),
                              ),
                            ),
                            Text(
                              'Stadium Food Guide',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'UPCOMING FIXTURES',
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              color: const Color(0xFF4CB572),
              letterSpacing: 2,
            ),
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
                  padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                  itemCount: filtered.length + 1,
                  itemBuilder: (context, index) {
                    if (index == filtered.length) {
                      return _buildQuickLinks();
                    }

                    final m = filtered[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1A13),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF4CB572).withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stage pill + time
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CB572).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  m['stage'] as String,
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 9,
                                    color: const Color(0xFF4CB572),
                                  ),
                                ),
                              ),
                              Text(
                                m['time'] as String,
                                style: GoogleFonts.spaceMono(
                                  fontSize: 12,
                                  color: const Color(0xFFF2C233),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Teams row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Team A
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(m['flag_a'] as String,
                                      style: const TextStyle(fontSize: 40)),
                                  const SizedBox(height: 6),
                                  Text(
                                    (m['team_a'] as String).toUpperCase(), // Added uppercase to match both "Space Mono uppercase" and Inter font rule intent, keeping Inter for font
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),

                              // VS
                              Text(
                                'VS',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFEBF2EE).withValues(alpha: 0.2),
                                ),
                              ),

                              // Team B
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(m['flag_b'] as String,
                                      style: const TextStyle(fontSize: 40)),
                                  const SizedBox(height: 6),
                                  Text(
                                    (m['team_b'] as String).toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          // Thin divider
                          Divider(
                            color: const Color(0xFF4CB572).withValues(alpha: 0.1),
                            height: 1,
                          ),
                          const SizedBox(height: 8),

                          // Venue & Date info
                          Row(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 12,
                                      color: const Color(0xFFEBF2EE).withValues(alpha: 0.3)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${m['city']} · ${m['stadium']}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFFEBF2EE).withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined,
                                      size: 11,
                                      color: const Color(0xFFEBF2EE).withValues(alpha: 0.3)),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(m['date'] as String),
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 10,
                                      color: const Color(0xFFEBF2EE).withValues(alpha: 0.3),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF152B1E),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  size: 14,
                                  color: Color(0xFF4CB572),
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
