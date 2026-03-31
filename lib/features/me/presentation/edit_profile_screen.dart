import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/supabase/supabase_config.dart';
import '../data/me_repository.dart';


class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialProfile;
  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _repo = MeRepository();
  late Map<String, dynamic> _profile;
  bool _saving = false;

  // Form Controllers
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _ageController;
  late String _gender;
  late String _nationality;
  late String _teamSupported;
  late bool _isLocal;
  late String _city;
  late List<String> _matchTypes;
  late List<String> _countriesToMatch;

  final List<Map<String, String>> _countries = [
    {'name': 'Brazil', 'flag': '🇧🇷'},
    {'name': 'France', 'flag': '🇫🇷'},
    {'name': 'Argentina', 'flag': '🇦🇷'},
    {'name': 'United States', 'flag': '🇺🇸'},
    {'name': 'England', 'flag': '🏴󠁧󠁢󠁥󠁮󠁧󠁿'},
    {'name': 'Germany', 'flag': '🇩🇪'},
    {'name': 'Spain', 'flag': '🇪🇸'},
    {'name': 'Portugal', 'flag': '🇵🇹'},
    {'name': 'Morocco', 'flag': '🇲🇦'},
    {'name': 'Japan', 'flag': '🇯🇵'},
    {'name': 'Nigeria', 'flag': '🇳🇬'},
    {'name': 'Mexico', 'flag': '🇲🇽'},
    {'name': 'Colombia', 'flag': '🇨🇴'},
    {'name': 'Senegal', 'flag': '🇸🇳'},
    {'name': 'Australia', 'flag': '🇦🇺'},
    {'name': 'South Korea', 'flag': '🇰🇷'},
    {'name': 'Netherlands', 'flag': '🇳🇱'},
    {'name': 'Italy', 'flag': '🇮🇹'},
    {'name': 'Belgium', 'flag': '🇧🇪'},
    {'name': 'Canada', 'flag': '🇨🇦'},
    {'name': 'Benin', 'flag': '🇧🇯'},
    {'name': 'Ghana', 'flag': '🇬🇭'},
    {'name': 'Cameroon', 'flag': '🇨🇲'},
    {'name': 'Uruguay', 'flag': '🇺🇾'},
    {'name': 'South Africa', 'flag': '🇿🇦'},
    {'name': 'Iran', 'flag': '🇮🇷'},
    {'name': 'Saudi Arabia', 'flag': '🇸🇦'},
    {'name': 'Togo', 'flag': '🇹🇬'},
    {'name': 'Ivory Coast', 'flag': '🇨🇮'},
    {'name': 'Tunisia', 'flag': '🇹🇳'},
    {'name': 'Poland', 'flag': '🇵🇱'},
    {'name': 'Croatia', 'flag': '🇭🇷'},
    {'name': 'Switzerland', 'flag': '🇨🇭'},
    {'name': 'Denmark', 'flag': '🇩🇪'},
    {'name': 'Sweden', 'flag': '🇸🇪'},
    {'name': 'Norway', 'flag': '🇳🇴'},
  ];

  final List<String> _cities = [
    'New York', 'Los Angeles', 'Miami', 'Chicago', 'Atlanta', 'Dallas', 
    'Houston', 'San Francisco', 'Seattle', 'Toronto', 'London', 'Paris', 
    'Berlin', 'Madrid', 'Rome', 'Dubai'
  ];

  @override
  void initState() {
    super.initState();
    _profile = Map<String, dynamic>.from(widget.initialProfile);
    _nameController = TextEditingController(text: _profile['name'] ?? '');
    _bioController = TextEditingController(text: _profile['bio'] ?? '');
    _ageController = TextEditingController(text: (_profile['age'] ?? '').toString());
    _gender = _profile['gender'] ?? 'Other';
    _nationality = _profile['nationality'] ?? '';
    _teamSupported = _profile['team_supported'] ?? '';
    _isLocal = _profile['is_local'] == true;
    _city = _profile['city'] ?? 'Miami';
    _matchTypes = List<String>.from(_profile['match_type_preference'] ?? []);
    _countriesToMatch = List<String>.from(_profile['countries_to_match'] ?? []);
  }

  Future<void> _saveTab(Map<String, dynamic> data) async {
    setState(() => _saving = true);
    try {
      final userId = SupabaseConfig.client.auth.currentUser!.id;
      await _repo.updateProfile(userId, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved ✅'), backgroundColor: Color(0xFF135E4B)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save ❌'), backgroundColor: Color(0xFFE83535)),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  void _showCountryPicker(String label, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1A13),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _CountryPickerSheet(
        countries: _countries,
        label: label,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF080F0C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF080F0C),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, true),
          ),
          title: Text('Edit Profile', style: GoogleFonts.spaceGrotesk(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            indicatorColor: const Color(0xFF4CB572),
            labelColor: const Color(0xFF4CB572),
            unselectedLabelColor: Colors.white.withValues(alpha: 0.4),
            labelStyle: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            tabs: const [
              Tab(text: 'ABOUT ME'),
              Tab(text: 'FOOTBALL'),
              Tab(text: 'PREFERENCES'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAboutMeTab(),
            _buildFootballTab(),
            _buildPreferencesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutMeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF152B1E),
                   backgroundImage: _profile['avatar_url'] != null 
                    ? NetworkImage(_profile['avatar_url']) 
                    : null,
                  child: _profile['avatar_url'] == null 
                    ? const Icon(Icons.person, size: 50, color: Colors.white24) 
                    : null,
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
                      if (file != null) {
                        final userId = SupabaseConfig.client.auth.currentUser!.id;
                        final url = await _repo.uploadAvatar(userId, File(file.path));
                        if (url != null) {
                          await _repo.updateProfile(userId, {'avatar_url': url});
                          setState(() => _profile['avatar_url'] = url);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Color(0xFF4CB572), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField('FULL NAME', _nameController),
          const SizedBox(height: 20),
          _buildTextField('AGE', _ageController, keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          _buildDropdownField('GENDER', _gender, ['Male', 'Female', 'Other'], (val) => setState(() => _gender = val!)),
          const SizedBox(height: 20),
          _buildTextField('BIO', _bioController, maxLines: 4),
          const SizedBox(height: 32),
          _buildSaveButton(() {
            _saveTab({
              'name': _nameController.text.trim(),
              'age': int.tryParse(_ageController.text) ?? _profile['age'],
              'gender': _gender,
              'bio': _bioController.text.trim(),
            });
          }),
        ],
      ),
    );
  }

  Widget _buildFootballTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPickerField('NATIONALITY', _nationality, () => _showCountryPicker('NATIONALITY', (c) => setState(() => _nationality = c))),
          const SizedBox(height: 20),
          _buildPickerField('TEAM I SUPPORT', _teamSupported, () => _showCountryPicker('TEAM I SUPPORT', (c) => setState(() => _teamSupported = c))),
          const SizedBox(height: 32),
          Text('IDENTITY', style: GoogleFonts.spaceMono(fontSize: 10, color: const Color(0xFF4CB572), letterSpacing: 2)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildIdentityToggle('🏠', 'Local', _isLocal, () => setState(() => _isLocal = true)),
              const SizedBox(width: 12),
              _buildIdentityToggle('✈️', 'Visiting', !_isLocal, () => setState(() => _isLocal = false)),
            ],
          ),
          if (_isLocal) ...[
            const SizedBox(height: 24),
            _buildDropdownField('CITY', _city, _cities, (val) => setState(() => _city = val!)),
          ],
          const SizedBox(height: 32),
          _buildSaveButton(() {
            _saveTab({
              'nationality': _nationality,
              'team_supported': _teamSupported,
              'is_local': _isLocal,
              'city': _isLocal ? _city : null,
            });
          }),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WHAT I\'M LOOKING FOR', style: GoogleFonts.spaceMono(fontSize: 10, color: const Color(0xFF4CB572), letterSpacing: 2)),
          const SizedBox(height: 12),
          _buildPreferenceCard('❤️', 'Dating & Romance', _matchTypes.contains('❤️ Dating & Romance'), () {
             setState(() => _matchTypes.contains('❤️ Dating & Romance') ? _matchTypes.remove('❤️ Dating & Romance') : _matchTypes.add('❤️ Dating & Romance'));
          }),
          const SizedBox(height: 8),
          _buildPreferenceCard('⚽', 'Fan Friends', _matchTypes.contains('⚽ Fan Friends'), () {
             setState(() => _matchTypes.contains('⚽ Fan Friends') ? _matchTypes.remove('⚽ Fan Friends') : _matchTypes.add('⚽ Fan Friends'));
          }),
          const SizedBox(height: 8),
          _buildPreferenceCard('🗺️', 'Local Guide', _matchTypes.contains('🗺️ Local Guide'), () {
             setState(() => _matchTypes.contains('🗺️ Local Guide') ? _matchTypes.remove('🗺️ Local Guide') : _matchTypes.add('🗺️ Local Guide'));
          }),
          const SizedBox(height: 32),
          Row(
            children: [
              Text('COUNTRIES TO MATCH', style: GoogleFonts.spaceMono(fontSize: 10, color: const Color(0xFF4CB572), letterSpacing: 2)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _countriesToMatch = _countries.map((e) => e['name']!).toList()),
                child: Text('SELECT ALL', style: GoogleFonts.spaceMono(fontSize: 10, color: Colors.white38)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCountriesGrid(),
          const SizedBox(height: 32),
          _buildSaveButton(() {
            _saveTab({
              'match_type_preference': _matchTypes,
              'countries_to_match': _countriesToMatch,
            });
          }),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.spaceMono(fontSize: 9, color: Colors.white38, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            fillColor: const Color(0xFF0D1A13),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.spaceMono(fontSize: 9, color: Colors.white38, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xFF0D1A13), borderRadius: BorderRadius.circular(12)),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF0D1A13),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
            items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPickerField(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.spaceMono(fontSize: 9, color: Colors.white38, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(color: const Color(0xFF0D1A13), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Text(value.isEmpty ? 'Select...' : value, style: GoogleFonts.inter(color: value.isEmpty ? Colors.white24 : Colors.white, fontSize: 15)),
                const Spacer(),
                const Icon(Icons.search, size: 18, color: Colors.white38),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityToggle(String emoji, String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF135E4B) : const Color(0xFF0D1A13),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF4CB572) : Colors.transparent),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.inter(color: isSelected ? Colors.white : Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceCard(String emoji, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CB572) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF4CB572) : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(color: isSelected ? Colors.white : Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildCountriesGrid() {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _countries.map((c) {
        final isSelected = _countriesToMatch.contains(c['name']);
        return GestureDetector(
          onTap: () => setState(() => isSelected ? _countriesToMatch.remove(c['name']) : _countriesToMatch.add(c['name']!)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF135E4B) : const Color(0xFF0D1A13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? const Color(0xFF4CB572) : Colors.transparent),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(c['flag']!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(c['name']!, style: GoogleFonts.inter(color: isSelected ? Colors.white : Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _saving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF135E4B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        child: _saving 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text('SAVE CHANGES', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final List<Map<String, String>> countries;
  final String label;
  final Function(String) onSelect;

  const _CountryPickerSheet({required this.countries, required this.label, required this.onSelect});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.countries.where((c) => c['name']!.toLowerCase().contains(_query.toLowerCase())).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.label, style: GoogleFonts.spaceGrotesk(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, color: Colors.white30), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            onChanged: (val) => setState(() => _query = val),
            decoration: InputDecoration(
              hintText: 'Search country...',
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.search, color: Colors.white30),
              fillColor: const Color(0xFF152B1E),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final c = filtered[index];
                return ListTile(
                  leading: Text(c['flag']!, style: const TextStyle(fontSize: 24)),
                  title: Text(c['name']!, style: GoogleFonts.inter(color: Colors.white)),
                  onTap: () {
                    widget.onSelect(c['name']!);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
