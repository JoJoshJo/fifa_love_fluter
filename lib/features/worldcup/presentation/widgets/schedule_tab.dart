import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fifalove_mobile/core/constants/colors.dart';
import 'package:fifalove_mobile/features/worldcup/data/worldcup_data.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  String _cityFilter = '';
  String _teamFilter = '';

  static const _teamColors = {
    'Brazil': Color(0xFF009B3A),
    'Mexico': Color(0xFF006341),
    'USA': Color(0xFF002868),
    'Canada': Color(0xFFC62828),
    'Argentina': Color(0xFF6CACE4),
    'France': Color(0xFF002395),
    'England': Color(0xFFC62828),
    'Portugal': Color(0xFFC62828),
    'Italy': Color(0xFF008C45),
    'Japan': Color(0xFF002868),
  };

  Color _getTeamColor(String team) {
    if (team.contains('TBD')) return const Color(0xFF9BB3AF);
    return _teamColors[team] ?? const Color(0xFF9BB3AF);
  }

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
      backgroundColor: Theme.of(context).cardColor,
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
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                title: Text(
                  'All Cities',
                  style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                trailing: _cityFilter.isEmpty
                    ? const Icon(LucideIcons.check, color: Color(0xFF4CB572), size: 18)
                    : null,
                onTap: () {
                  setState(() => _cityFilter = '');
                  Navigator.pop(context);
                },
              ),
              ...cities.map((c) => ListTile(
                    title: Text(c, style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyLarge?.color)),
                    trailing: _cityFilter == c
                        ? const Icon(LucideIcons.check, color: Color(0xFF4CB572), size: 18)
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
                color: Theme.of(context).primaryColor,
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
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD166),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.mapPin,
                          size: 20, color: Color(0xFFF2C233)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'FAN ZONE',
                              style: GoogleFonts.spaceMono(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF2C233),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Watch parties & music',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5A4500),
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
                    color: const Color(0xFFF0FFF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF9AE6B4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.utensils,
                          size: 20, color: Color(0xFF004B3A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'LOCAL EATS',
                              style: GoogleFonts.spaceMono(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF004B3A),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Best taco spots & BBQ',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF004B3A),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final text = isLight ? FifaColors.textPrimaryLight : FifaColors.textPrimaryDark;
    const accentGreen = FifaColors.accent;
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
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Theme.of(context).brightness == Brightness.light 
                          ? Border.all(color: Theme.of(context).dividerColor)
                          : null,
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.mapPin,
                            size: 14, color: FifaColors.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _cityFilter.isEmpty ? 'All Cities' : _cityFilter,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        Icon(LucideIcons.chevronDown,
                            size: 16,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.40)),
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
                        fontSize: 12, color: FifaColors.error),
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
              color: accentGreen,
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
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.40),
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
                      decoration: BoxDecoration(
                        color: isLight ? FifaColors.lightCard : FifaColors.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isLight ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ] : null,
                        border: isLight ? Border.all(color: FifaColors.lightBorder) : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 4px Accent Bar
                            Container(
                              height: 4,
                              width: double.infinity,
                              color: _getTeamColor(m['team_a'] as String),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
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
                                          color: accentGreen.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          m['stage'] as String,
                                          style: GoogleFonts.spaceMono(
                                            fontSize: 9,
                                            color: accentGreen,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        m['time'] as String,
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 12,
                                          color: FifaColors.gold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Teams row
                                  Row(
                                    children: [
                                      // Team A
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Builder(builder: (context) {
                                              final flag = m['flag_a'];
                                              return flag is IconData
                                                  ? Icon(flag, size: 32, color: const Color(0xFF9BB3AF))
                                                  : Text(flag as String, style: const TextStyle(fontSize: 32));
                                            }),
                                            const SizedBox(height: 4),
                                            Text(
                                              (m['team_a'] as String).toUpperCase(),
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).textTheme.titleLarge?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // VS
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          'vs',
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            fontStyle: FontStyle.italic,
                                            color: text.withValues(alpha: 0.3),
                                          ),
                                        ),
                                      ),

                                      // Team B
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Builder(builder: (context) {
                                              final flag = m['flag_b'];
                                              return flag is IconData
                                                  ? Icon(flag, size: 32, color: const Color(0xFF9BB3AF))
                                                  : Text(flag as String, style: const TextStyle(fontSize: 32));
                                            }),
                                            const SizedBox(height: 4),
                                            Text(
                                              (m['team_b'] as String).toUpperCase(),
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).textTheme.titleLarge?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),
                                  // Thin divider
                                  if (Theme.of(context).brightness == Brightness.light)
                                    Divider(
                                      color: Theme.of(context).dividerColor,
                                      height: 1,
                                    ),
                                  const SizedBox(height: 8),

                                  // Venue & Date info
                                  Row(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(LucideIcons.mapPin,
                                              size: 12,
                                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${m['city']} · ${m['stadium']}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          Icon(LucideIcons.calendar,
                                              size: 11,
                                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3)),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(m['date'] as String),
                                            style: GoogleFonts.spaceMono(
                                              fontSize: 10,
                                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          LucideIcons.bell,
                                          size: 14,
                                          color: accentGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
