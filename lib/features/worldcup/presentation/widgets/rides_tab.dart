import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/worldcup_data.dart';

class RidesTab extends StatefulWidget {
  const RidesTab({super.key});

  @override
  State<RidesTab> createState() => _RidesTabState();
}

class _RidesTabState extends State<RidesTab> {
  String _selectedCity = 'Dallas';
  int _activeSubTab = 0;

  static const _cities = ['Dallas', 'Los Angeles', 'Atlanta', 'Mexico City', 'Vancouver'];
  static const _subTabs = ['🚗 Rideshare', '🎩 Chauffeur', '🗺️ Tours'];

  Widget _card({required Widget child, Color? borderColor, Color? bgColor}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFF0D1A13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? const Color(0xFF1E4A33)),
      ),
      child: child,
    );
  }

  Widget _rideshareContent(Map<String, dynamic> data) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      children: [
        // Apps
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AVAILABLE APPS',
                  style: GoogleFonts.spaceMono(
                      fontSize: 9, color: const Color(0xFF4CB572), letterSpacing: 1.5)),
              const SizedBox(height: 12),
              ...(data['apps'] as List).map((app) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Text('🚗', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Text(app as String,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ],
                    ),
                  )),
            ],
          ),
        ),

        // Airport tip
        _card(
          borderColor: const Color(0xFFF2C233).withValues(alpha: 0.3),
          bgColor: const Color(0xFFF2C233).withValues(alpha: 0.05),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.flight_land, size: 18, color: Color(0xFFF2C233)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AIRPORT → STADIUM',
                        style: GoogleFonts.spaceMono(
                            fontSize: 9, color: const Color(0xFFF2C233), letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(data['airport_tip'] as String,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.white.withValues(alpha: 0.70), height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Game day warning
        _card(
          borderColor: const Color(0xFFE83535).withValues(alpha: 0.3),
          bgColor: const Color(0xFFE83535).withValues(alpha: 0.05),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFE83535)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GAME DAY WARNING',
                        style: GoogleFonts.spaceMono(
                            fontSize: 9, color: const Color(0xFFE83535), letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(data['game_day_warning'] as String,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.white.withValues(alpha: 0.70), height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Transit tip
        if (data['transit'] != null)
          _card(
            borderColor: const Color(0xFF4CB572).withValues(alpha: 0.3),
            bgColor: const Color(0xFF4CB572).withValues(alpha: 0.05),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.subway_outlined, size: 18, color: Color(0xFF4CB572)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BEST TRANSIT OPTION',
                          style: GoogleFonts.spaceMono(
                              fontSize: 9, color: const Color(0xFF4CB572), letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text(data['transit'] as String,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _chauffeurContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      children: chauffeurServices.map((s) {
        return _card(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s['icon'] as String, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['name'] as String,
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(s['coverage'] as String,
                        style: GoogleFonts.spaceMono(
                            fontSize: 9, color: const Color(0xFF4CB572))),
                    const SizedBox(height: 6),
                    Text(s['description'] as String,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.white.withValues(alpha: 0.60), height: 1.4)),
                    const SizedBox(height: 8),
                    Text(s['price'] as String,
                        style: GoogleFonts.spaceMono(
                            fontSize: 10, color: const Color(0xFFF2C233))),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _toursContent() {
    final cityTours = toursData
        .where((t) => t['city'] == _selectedCity)
        .toList();

    if (cityTours.isEmpty) {
      return Center(
        child: Text(
          'No tours listed for $_selectedCity yet.',
          style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      children: cityTours.map((t) {
        return _card(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t['icon'] as String, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(t['name'] as String,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                        Text(t['price'] as String,
                            style: GoogleFonts.spaceMono(
                                fontSize: 10, color: const Color(0xFFF2C233))),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 12, color: Colors.white.withValues(alpha: 0.40)),
                        const SizedBox(width: 4),
                        Text(t['duration'] as String,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.45))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(t['description'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.white.withValues(alpha: 0.60), height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rideData = ridesData.firstWhere(
      (r) => r['city'] == _selectedCity,
      orElse: () => ridesData.first,
    );

    return Column(
      children: [
        // City selector
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _cities.length,
            itemBuilder: (context, i) {
              final city = _cities[i];
              final isActive = city == _selectedCity;
              return GestureDetector(
                onTap: () => setState(() => _selectedCity = city),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF135E4B) : const Color(0xFF152B1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isActive ? const Color(0xFF4CB572) : const Color(0xFF1E4A33)),
                  ),
                  child: Text(
                    city,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.45),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Sub-tab bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: List.generate(_subTabs.length, (i) {
              final isActive = i == _activeSubTab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeSubTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < _subTabs.length - 1 ? 4 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF135E4B) : const Color(0xFF152B1E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isActive ? const Color(0xFF4CB572) : const Color(0xFF1E4A33)),
                    ),
                    child: Text(
                      _subTabs[i],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        color: isActive
                            ? const Color(0xFF4CB572)
                            : Colors.white.withValues(alpha: 0.40),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // Content
        Expanded(
          child: IndexedStack(
            index: _activeSubTab,
            children: [
              _rideshareContent(rideData),
              _chauffeurContent(),
              _toursContent(),
            ],
          ),
        ),
      ],
    );
  }
}
