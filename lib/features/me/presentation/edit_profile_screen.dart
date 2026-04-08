import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/colors.dart';
import '../data/me_repository.dart';
import '../../../core/supabase/supabase_config.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialProfile;
  final int initialTab;

  const EditProfileScreen({
    super.key,
    required this.initialProfile,
    this.initialTab = 0,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = MeRepository();
  bool _saving = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _bioController;

  // Profile Data
  late Map<String, dynamic> _profile = {};
  late String _gender;
  late String _nationality;
  late String _teamSupported;
  late bool _isLocal;
  late String _city;
  late List<String> _matchTypes;
  late List<String> _countriesToMatch;
  
  static const _worldCupTeams = [
    'Argentina', 'Australia', 'Belgium', 'Bolivia', 'Brazil',
    'Cameroon', 'Canada', 'Chile', 'Colombia', 'Costa Rica',
    'Croatia', 'Czech Republic', 'Denmark', 'Ecuador', 'Egypt',
    'England', 'France', 'Germany', 'Ghana', 'Indonesia',
    'Iran', 'Italy', 'Ivory Coast', 'Jamaica', 'Japan',
    'Mali', 'Mexico', 'Morocco', 'Netherlands', 'New Zealand',
    'Nigeria', 'Panama', 'Paraguay', 'Peru', 'Poland',
    'Portugal', 'Qatar', 'Saudi Arabia', 'Senegal', 'Serbia',
    'South Korea', 'Spain', 'Switzerland', 'Tunisia', 'Turkey',
    'USA', 'Uruguay', 'Venezuela'
  ];
  
  // Media
  String? _avatarUrl;
  XFile? _pickedFile;
  Uint8List? _imageBytes;

  final List<String> _cities = [
    'Doha', 'Al Khor', 'Al Wakrah', 'Lusail', 'Rayyan', 'Dallas'
  ];

  String? _flag(String nationality) {
    const flags = {
      'Argentina': '🇦🇷', 'Australia': '🇦🇺', 'Belgium': '🇧🇪', 'Brazil': '🇧🇷',
      'Canada': '🇨🇦', 'Colombia': '🇨🇴', 'Croatia': '🇭🇷', 'Ecuador': '🇪🇨',
      'England': '🏴', 'France': '🇫🇷', 'Germany': '🇩🇪', 'Ghana': '🇬🇭',
      'Italy': '🇮🇹', 'Japan': '🇯🇵', 'Mexico': '🇲🇽', 'Morocco': '🇲🇦',
      'Netherlands': '🇳🇱', 'Nigeria': '🇳🇬', 'Peru': '🇵🇪', 'Poland': '🇵🇱',
      'Portugal': '🇵🇹', 'Saudi Arabia': '🇸🇦', 'Senegal': '🇸🇳',
      'South Korea': '🇰🇷', 'Spain': '🇪🇸', 'USA': '🇺🇸', 'Uruguay': '🇺🇾',
    };
    return flags[nationality];
  }

  String _normalizeGender(String? raw) {
    if (raw == null) return 'Other';
    final lower = raw.toLowerCase();
    if (lower == 'male') return 'Male';
    if (lower == 'female') return 'Female';
    return 'Other';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: (widget.initialTab >= 0 && widget.initialTab < 3)
          ? widget.initialTab
          : 0,
    );
    try {
      _profile = Map<String, dynamic>.from(widget.initialProfile);

      _nameController = TextEditingController(text: _profile['name'] as String? ?? '');
      _bioController = TextEditingController(text: _profile['bio'] as String? ?? '');
      _ageController = TextEditingController(text: (_profile['age'] != null) ? _profile['age'].toString() : '');

      _gender = _normalizeGender(_profile['gender'] as String?);
      _nationality = _profile['nationality'] as String? ?? '';
      _matchTypes = List<String>.from(_profile['match_type_preference'] ?? []);
      _isLocal = _profile['is_local'] as bool? ?? false;
      _city = _profile['city'] as String? ?? 'Dallas';
      if (!_cities.contains(_city)) {
        _city = 'Dallas';
      }
      _countriesToMatch = List<String>.from(_profile['countries_to_match'] ?? []);
      
      _teamSupported = _profile['team_supported'] as String? ?? '';
      if (!_worldCupTeams.contains(_teamSupported)) {
        _teamSupported = '';
      }
      
      _avatarUrl = _profile['avatar_url'] as String?;
    } catch (e) {
      _nameController = TextEditingController();
      _bioController = TextEditingController();
      _ageController = TextEditingController();
      _gender = 'Other';
      _nationality = '';
      _matchTypes = [];
      _isLocal = false;
      _city = 'Dallas';
      _countriesToMatch = [];
      _teamSupported = '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  bool _hasMatchType(String type) {
    return _matchTypes.contains(type);
  }

  void _toggleMatchType(String type) {
    setState(() {
      if (_matchTypes.contains(type)) {
        _matchTypes.remove(type);
      } else {
        _matchTypes.add(type);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final userId = SupabaseConfig.client.auth.currentUser!.id;
      
      String? finalAvatarUrl = _avatarUrl;
      if (_pickedFile != null) {
        finalAvatarUrl = await _repo.uploadAvatar(userId, _pickedFile!);
      }

      final updates = {
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? (_profile['age'] as int? ?? 18),
        'bio': _bioController.text.trim(),
        'gender': _gender,
        'nationality': _nationality,
        'team_supported': _teamSupported.isEmpty ? null : _teamSupported,
        'avatar_url': finalAvatarUrl,
        'interests': _matchTypes,
        'is_local': _isLocal,
        'city': _city,
        'countries_to_match': _countriesToMatch,
      };

      await _repo.updateProfile(userId, updates);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showNationalityPicker() {
    final theme = Theme.of(context);
    final countries = [
      'Argentina', 'Australia', 'Belgium', 'Brazil', 'Canada', 
      'Colombia', 'Croatia', 'Ecuador', 'England', 'France', 
      'Germany', 'Ghana', 'Italy', 'Japan', 'Mexico', 
      'Morocco', 'Netherlands', 'Nigeria', 'Peru', 'Poland', 
      'Portugal', 'Saudi Arabia', 'Senegal', 'South Korea', 'Spain', 'USA'
    ];

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _CountryPickerSheet(
        title: 'SELECT NATIONALITY',
        countries: countries,
        onSelect: (c) => setState(() => _nationality = c),
      ),
    );
  }

  void _showTeamPicker() {
    final theme = Theme.of(context);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _TeamPickerSheet(
        onSelect: (t) => setState(() => _teamSupported = t),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? const Color(0xFFF5F0E8) : const Color(0xFF080F0C);
    final textColor = isLight ? const Color(0xFF0D2B1E) : Colors.white;
    final textMuted = isLight ? const Color(0xFF9BB3AF) : Colors.white.withValues(alpha: 0.35);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          )),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: TurfArdorColors.emeraldSpring)))
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: GestureDetector(
                  onTap: _save,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF135E4B),
                          Color(0xFF4CB572),
                        ]),
                      borderRadius:
                        BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text('Save',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: TurfArdorColors.emeraldSpring,
          labelColor: TurfArdorColors.emeraldSpring,
          unselectedLabelColor: textMuted,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'ABOUT'),
            Tab(text: 'FOOTBALL'),
            Tab(text: 'MATCHING'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAboutMeTab(isLight, textColor, textMuted),
          _buildFootballIdentityTab(isLight, textColor, textMuted),
          _buildPreferencesTab(isLight, textColor, textMuted),
        ],
      ),
    );
  }

  Widget _buildAboutMeTab(bool isLight, Color textColor, Color textMuted) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: textColor.withValues(alpha: 0.1),
                  backgroundImage: _imageBytes != null 
                      ? MemoryImage(_imageBytes!) 
                      : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null) as ImageProvider?,
                  child: (_imageBytes == null && _avatarUrl == null) ? Icon(LucideIcons.user, size: 50, color: textMuted) : null,
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: TurfArdorColors.emeraldSpring, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.camera, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildTextField('Full Name', _nameController, isLight, textColor, textMuted, hint: 'How others see you'),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildTextField('Age', _ageController, isLight, textColor, textMuted, hint: 'e.g. 24', keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: _buildDropdownField('Gender', ['Male', 'Female', 'Non-binary', 'Prefer not to say'], _gender, (v) => setState(() => _gender = v ?? 'Other'), isLight, textColor, textMuted)),
          ],
        ),
        const SizedBox(height: 20),
        _buildTextField('Bio', _bioController, isLight, textColor, textMuted, hint: 'Tell fans about your football journey...', maxLines: 4),
      ],
    );
  }

  Widget _buildFootballIdentityTab(bool isLight, Color textColor, Color textMuted) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Builder(builder: (context) {
          final f = _flag(_nationality);
          return _buildPickerField(
            'Nationality',
            _nationality.isEmpty ? 'Select Country' : _nationality,
            _showNationalityPicker,
            isLight, textColor, textMuted,
            icon: f == null ? LucideIcons.flag : null,
            flagEmoji: f,
          );
        }),
        const SizedBox(height: 20),
        
        // Team Supported Picker
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SUPPORTED TEAM',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4CB572),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showTeamPicker(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF2FAF6) : const Color(0xFF152B1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLight ? const Color(0xFFE8DDD0) : const Color(0xFF1E4A33),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.trophy, size: 18, color: Color(0xFF4CB572)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _teamSupported.isNotEmpty ? _teamSupported : 'Select your team...',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: _teamSupported.isNotEmpty ? textColor : textMuted,
                        ),
                      ),
                    ),
                    Icon(LucideIcons.chevronDown, size: 18, color: textMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TurfArdorColors.emeraldSpring.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: isLight ? Border.all(color: TurfArdorColors.emeraldSpring.withValues(alpha: 0.1)) : null,
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.info, size: 20, color: TurfArdorColors.emeraldSpring),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your football identity helps us match you with compatible fans.',
                  style: GoogleFonts.inter(fontSize: 13, color: textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesTab(bool isLight, Color textColor, Color textMuted) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          "I'M LOOKING FOR...",
          style: GoogleFonts.spaceMono(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4CB572),
            letterSpacing: 2),
        ),
        const SizedBox(height: 8),
        Text(
          "Select the types of connections you want to make during the World Cup.",
          style: GoogleFonts.inter(fontSize: 14, color: textMuted),
        ),
        const SizedBox(height: 24),
        _buildPreferenceCard(
          const Icon(LucideIcons.heart, size: 22, color: Color(0xFFE8437A)),
          'Dating & Romance', 
          _hasMatchType('Dating & Romance'),
          () => _toggleMatchType('Dating & Romance'),
          isLight, textColor
        ),
        const SizedBox(height: 12),
        _buildPreferenceCard(
          const Icon(LucideIcons.trophy, size: 22, color: Color(0xFF4CB572)),
          'Fan Friends', 
          _hasMatchType('Fan Friends'),
          () => _toggleMatchType('Fan Friends'),
          isLight, textColor
        ),
        const SizedBox(height: 12),
        _buildPreferenceCard(
          const Icon(LucideIcons.mapPin, size: 22, color: Color(0xFFF2C233)),
          'Local Guide', 
          _hasMatchType('Local Guide'),
          () => _toggleMatchType('Local Guide'),
          isLight, textColor
        ),
      ],
    );
  }

  Widget _buildPreferenceCard(Widget icon, String title, bool isSelected, VoidCallback onTap, bool isLight, Color textColor) {
    final cardColor = isLight ? Colors.white : const Color(0xFF0D1A13);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
            ? const Color(0xFF135E4B) 
            : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isSelected 
            ? Border.all(
                color: const Color(0xFF4CB572),
                width: 1.5,
              )
            : (isLight ? Border.all(
                color: const Color(0xFFE8DDD0),
                width: 1.5,
              ) : null),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : textColor,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isLight, Color textColor, Color textMuted, {String? hint, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    final inputColor = isLight ? Colors.white : const Color(0xFF152B1E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
          style: GoogleFonts.spaceMono(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4CB572),
            letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: textMuted.withValues(alpha: 0.5)),
            filled: true,
            fillColor: inputColor,
            border: isLight 
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE8DDD0)))
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
            enabledBorder: isLight 
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE8DDD0)))
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options, String value, ValueChanged<String?> onChanged, bool isLight, Color textColor, Color textMuted) {
    final inputColor = isLight ? const Color(0xFFF2FAF6) : const Color(0xFF152B1E);
    final cardColor = isLight ? Colors.white : const Color(0xFF0D1A13);

    // Ensure value exists in options
    final safeValue = options.contains(value) ? value : options.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold, color: TurfArdorColors.emeraldSpring, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: inputColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              isExpanded: true,
              dropdownColor: cardColor,
              style: GoogleFonts.inter(color: textColor),
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: GoogleFonts.inter(color: textColor)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerField(String label, String value, VoidCallback onTap, bool isLight, Color textColor, Color textMuted, {IconData? icon, String? flagEmoji}) {
    final inputColor = isLight ? const Color(0xFFF2FAF6) : const Color(0xFF152B1E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold, color: TurfArdorColors.emeraldSpring, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: inputColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isLight ? const Color(0xFFE8DDD0) : const Color(0xFF1E4A33)),
            ),
            child: Row(
              children: [
                if (flagEmoji != null)
                  Text(flagEmoji, style: const TextStyle(fontSize: 18))
                else if (icon != null)
                  Icon(icon, size: 18, color: TurfArdorColors.emeraldSpring),
                const SizedBox(width: 12),
                Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 15, color: value == 'Select Country' ? textMuted : textColor))),
                Icon(LucideIcons.chevronDown, size: 18, color: textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CountryPickerSheet extends StatelessWidget {
  final String title;
  final List<String> countries;
  final Function(String) onSelect;

  const _CountryPickerSheet({
    required this.title,
    required this.countries,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? const Color(0xFFF5F0E8) : const Color(0xFF0D1A13);
    final inputColor = isLight ? Colors.white : const Color(0xFF152B1E);
    final textColor = isLight ? const Color(0xFF0D2B1E) : Colors.white;
    final textMuted = isLight ? const Color(0xFF9BB3AF) : Colors.white38;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: GoogleFonts.spaceMono(fontSize: 12, color: TurfArdorColors.emeraldSpring, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              style: GoogleFonts.inter(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search country...',
                hintStyle: GoogleFonts.inter(color: textMuted.withValues(alpha: 0.5)),
                prefixIcon: const Icon(LucideIcons.search, color: TurfArdorColors.emeraldSpring, size: 20),
                filled: true,
                fillColor: inputColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: countries.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(countries[i], style: GoogleFonts.inter(color: textColor)),
                onTap: () {
                  onSelect(countries[i]);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamPickerSheet extends StatefulWidget {
  final Function(String) onSelect;

  const _TeamPickerSheet({required this.onSelect});

  @override
  State<_TeamPickerSheet> createState() => _TeamPickerSheetState();
}

class _TeamPickerSheetState extends State<_TeamPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? Colors.white : const Color(0xFF0D1C13);
    final textColor = isLight ? const Color(0xFF0D2B1E) : Colors.white;
    final textMuted = isLight ? const Color(0xFF9BB3AF) : Colors.white.withValues(alpha: 0.35);

    final filtered = _EditProfileScreenState._worldCupTeams.where((t) {
      return t.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Your Team',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                style: GoogleFonts.inter(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search teams...',
                  hintStyle: GoogleFonts.inter(color: textMuted),
                  prefixIcon: const Icon(LucideIcons.search, size: 20, color: Color(0xFF4CB572)),
                  filled: true,
                  fillColor: isLight ? const Color(0xFFF2FAF6) : const Color(0xFF152B1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: filtered.length,
                itemBuilder: (context, i) => InkWell(
                  onTap: () {
                    widget.onSelect(filtered[i]);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: textMuted.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      filtered[i],
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
