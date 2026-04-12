import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'email_confirm_screen.dart';
import 'widgets/country_selector_sheet.dart';
import '../../../core/constants/colors.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../shared/presentation/main_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // STEP 1 STATE
  Uint8List? _profileImageBytes;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  final List<String> _genders = ["Male", "Female", "Non-binary", "Prefer not to say"];

  // STEP 2 STATE
  String? _nationality;
  String? _teamSupported;
  bool _isLocal = true;
  String? _city;
  final List<String> _topCountries = ["Argentina", "Australia", "Austria", "Belgium", "Brazil", "Cameroon", "Canada", "Chile", "Colombia", "Costa Rica", "Croatia", "Denmark", "Ecuador", "Egypt", "England", "France", "Germany", "Ghana", "Greece", "Iran", "Italy", "Ivory Coast", "Jamaica", "Japan", "Mexico", "Morocco", "Netherlands", "New Zealand", "Nigeria", "Norway", "Panama", "Peru", "Poland", "Portugal", "Qatar", "Saudi Arabia", "Senegal", "Serbia", "South Korea", "Spain", "Sweden", "Switzerland", "Tunisia", "Turkey", "USA", "Uruguay", "Venezuela", "Wales"];
  final List<String> _hostCities = ["Dallas", "Los Angeles", "New York/New Jersey", "San Francisco Bay Area", "Seattle", "Kansas City", "Boston", "Miami", "Atlanta", "Houston", "Philadelphia", "Vancouver", "Toronto", "Guadalajara", "Mexico City", "Monterrey"];

  // STEP 3 STATE
  final List<String> _selectedIntentions = [];
  final List<String> _countriesToMatch = [];
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    }
  }

  void _prevStep() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _profileImageBytes = bytes;
      });
    }
  }
  
  void _submitProfile() async {
    // 1. Validation
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final age = int.tryParse(_ageController.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name'), backgroundColor: Color(0xFFC62828)),
      );
      return;
    }

    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be at least 18 years old'), backgroundColor: Color(0xFFC62828)),
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w\-\.+]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address'), backgroundColor: Color(0xFFC62828)),
      );
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms of Service'), backgroundColor: Color(0xFFC62828)),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Color(0xFFC62828)),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 1. Authenticate with Supabase
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'https://jojoshjo.github.io/fifa_love_fluter/',
        data: {
          'name': _nameController.text.trim(),
          'age': int.tryParse(_ageController.text) ?? 18,
          'gender': _selectedGender,
          'nationality': _nationality,
          'team_supported': _teamSupported,
          'is_local': _isLocal,
          'city': _isLocal ? _city : null,
          'match_type_preference': _selectedIntentions,
          'countries_to_match': _countriesToMatch,
        },
      );
      
      final user = response.user;
      
      // Supabase returns a user with identities = [] if email already exists
      if (user != null && (user.identities == null || user.identities!.isEmpty)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account already exists. Check your email or try signing in.'),
              backgroundColor: Color(0xFFF2C233),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => EmailConfirmScreen(email: email)),
          );
        }
        return;
      }
      
      if (user != null) {
        // Signup success - user metadata already stored in session


        try {
          await SupabaseConfig.client.from('profiles').upsert({
            'id': user.id,
            'name': _nameController.text.trim(),
            'age': int.tryParse(_ageController.text) ?? 18,
            'gender': _selectedGender,
            'nationality': _nationality,
            'team_supported': _teamSupported,
            'is_local': _isLocal,
            'city': _isLocal ? _city : null,
            'match_type_preference': _selectedIntentions,
            'countries_to_match': _countriesToMatch,
          });

        } catch (e) {
          debugPrint('PROFILE UPSERT BLOCKED/FAILED: $e');
        }

        if (mounted) {
          if (response.session != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => EmailConfirmScreen(email: email)),
            );
          }
        }
      }
      } catch (e) {
        if (mounted) {
          String message = 'Error: ${e.toString()}';
          if (e is AuthException) message = e.message;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('SUBMIT_ERROR: $message'),
              backgroundColor: TurfArdorColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 10), // Give them time to read it
            ),
          );
        }
      } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _getPasswordStrength(String password) {
    int s = 0;
    if (password.length >= 8) s++;
    if (password.contains(RegExp(r'[A-Z]'))) s++;
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[!@#\$&*~]'))) s++;
    return s == 0 && password.isNotEmpty ? 1 : s;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? const Color(0xFFF5F0E8) : const Color(0xFF080F0C);
    final card = isLight ? Colors.white : const Color(0xFF0D1A13);
    final text = isLight ? const Color(0xFF0D2B1E) : const Color(0xFFEBF2EE);
    final muted = isLight ? const Color(0xFF6B9E8A) : const Color(0xFF9BB3AF);
    final border = isLight ? const Color(0xFFE8DDD0) : const Color(0xFF1E4A33);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            _buildProgressBar(context),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                   _buildStep1(context),
                   _buildStep2(context),
                   _buildStep3(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final text = isLight ? const Color(0xFF0D2B1E) : const Color(0xFFEBF2EE);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: text),
            onPressed: _prevStep,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final active = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: active ? 24 : 8,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF4CB572) : text.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final text = isLight ? const Color(0xFF0D2B1E) : const Color(0xFFEBF2EE);

    return LinearProgressIndicator(
      value: (_currentPage + 1) / 3,
      backgroundColor: text.withValues(alpha: 0.05),
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE8437A)),
      minHeight: 2,
    );
  }
  
  Widget _buildStep1(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final text = isLight ? const Color(0xFF0D2B1E) : const Color(0xFFEBF2EE);
    final card = isLight ? Colors.white : const Color(0xFF0D1A13);

    bool canContinue = _profileImageBytes != null &&
                       _nameController.text.isNotEmpty && 
                       (int.tryParse(_ageController.text) ?? 0) >= 18 && 
                       _selectedGender != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Tell us about you", 
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28, 
              fontWeight: FontWeight.bold, 
              color: text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You can always change this later", 
            style: GoogleFonts.inter(
              fontSize: 14, 
              color: text.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),

          // Photo
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8437A).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE8437A).withValues(alpha: 0.3), 
                        width: 2,
                      ),
                      image: _profileImageBytes != null 
                        ? DecorationImage(image: MemoryImage(_profileImageBytes!), fit: BoxFit.cover) 
                        : null,
                    ),
                    child: _profileImageBytes == null 
                      ? const Icon(Icons.camera_alt, color: Color(0xFFE8437A), size: 32) 
                      : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Add Photo", 
                  style: GoogleFonts.spaceMono(
                    fontSize: 11, 
                    color: text.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Name
          _buildLabel(context, "YOUR NAME"),
          TextFormField(
            controller: _nameController,
            style: GoogleFonts.inter(color: text),
            onChanged: (v) => setState((){}),
            decoration: const InputDecoration(
              hintText: "What do people call you?",
            ),
          ),
          const SizedBox(height: 24),

          // Age
          _buildLabel(context, "YOUR AGE"),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(color: text),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => setState((){}),
            decoration: const InputDecoration(
              hintText: "Must be 18+",
            ),
          ),
          const SizedBox(height: 24),

          // Gender
          _buildLabel(context, "GENDER"),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genders.map((g) {
              final isSelected = _selectedGender == g;
              return GestureDetector(
                onTap: () => setState(() => _selectedGender = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE8437A) : card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFE8437A) : text.withValues(alpha: 0.2),
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: const Color(0xFFE8437A).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ] : null,
                  ),
                  child: Text(
                    g, 
                    style: GoogleFonts.inter(
                      fontSize: 14, 
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : text,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 48),
          _buildContinueBtn(canContinue, _nextStep),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final text = isLight ? const Color(0xFF0D2B1E) : const Color(0xFFEBF2EE);
    
    bool canContinue = _nationality != null && _teamSupported != null && (!_isLocal || _city != null);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Your football identity", 
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28, 
              fontWeight: FontWeight.bold, 
              color: text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This is how fans find you", 
            style: GoogleFonts.inter(
              fontSize: 14, 
              color: text.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),

          _buildLabel(context, "YOUR NATIONALITY"),
          GestureDetector(
            onTap: () => _showCountryPicker((val) => setState(() => _nationality = val)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF131F19), 
                borderRadius: BorderRadius.circular(12),
                border: _nationality != null 
                  ? Border.all(color: const Color(0xFF4CB572).withValues(alpha: 0.5))
                  : null,
              ),
              child: Row(
                children: [
                  Text(
                    _nationality ?? "Select Nationality", 
                    style: GoogleFonts.inter(
                      color: _nationality != null ? text : text.withValues(alpha: 0.5),
                      fontWeight: _nationality != null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.expand_more, color: text.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildLabel(context, "TEAM YOU SUPPORT"),
          GestureDetector(
            onTap: () => _showCountryPicker((val) => setState(() => _teamSupported = val)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF131F19), 
                borderRadius: BorderRadius.circular(12),
                border: _teamSupported != null 
                  ? Border.all(color: const Color(0xFF4CB572).withValues(alpha: 0.5))
                  : null,
              ),
              child: Row(
                children: [
                  Text(
                    _teamSupported ?? "Select Team", 
                    style: GoogleFonts.inter(
                      color: _teamSupported != null ? text : text.withValues(alpha: 0.5),
                      fontWeight: _teamSupported != null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.expand_more, color: text.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(child: _buildToggleCard(true, LucideIcons.home, "I'm a Local", "I live here")),
              const SizedBox(width: 16),
              Expanded(child: _buildToggleCard(false, LucideIcons.plane, "I'm Visiting", "I'm a tourist")),
            ],
          ),
          
          if (_isLocal) ...[
            const SizedBox(height: 32),
            _buildLabel(context, "YOUR CITY"),
            GestureDetector(
              onTap: () => _showCityPicker(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white : const Color(0xFF131F19), 
                  borderRadius: BorderRadius.circular(12),
                  border: _city != null 
                    ? Border.all(color: const Color(0xFF4CB572).withValues(alpha: 0.5))
                    : null,
                ),
                child: Row(
                  children: [
                    Text(
                      _city ?? "Select Host City", 
                      style: GoogleFonts.inter(
                        color: _city != null ? text : text.withValues(alpha: 0.5),
                        fontWeight: _city != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.expand_more, color: text.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 48),
          _buildContinueBtn(canContinue, _nextStep),
        ],
      ),
    );
  }
  
  Widget _buildToggleCard(bool isLocalValue, IconData icon, String title, String sub) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final text = isLight ? const Color(0xFF0D2B1E) : const Color(0xFFEBF2EE);
    final card = isLight ? Colors.white : const Color(0xFF131F19);
    
    bool isSelected = _isLocal == isLocalValue;
    return GestureDetector(
      onTap: () => setState(() {
        _isLocal = isLocalValue;
        if (!_isLocal) _city = null; 
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF135E4B) : card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CB572) : text.withValues(alpha: 0.1), 
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: TurfArdorColors.emeraldSpring.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: isSelected ? Colors.white : TurfArdorColors.emeraldSpring),
            const SizedBox(height: 8),
            Text(
              title, 
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, 
                color: isSelected ? Colors.white : text, 
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub, 
              style: GoogleFonts.inter(
                fontSize: 12, 
                color: isSelected ? Colors.white.withValues(alpha: 0.7) : text.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker(Function(String) onSelect) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final text = isLight ? const Color(0xFF0D2B1E) : const Color(0xFFEBF2EE);
    final bg = isLight ? const Color(0xFFF5F0E8) : const Color(0xFF080F0C);

    showModalBottomSheet(
      context: context, 
      backgroundColor: bg, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _topCountries.length,
          itemBuilder: (ctx, i) {
            return ListTile(
              title: Text(_topCountries[i], style: GoogleFonts.inter(color: text)),
              onTap: () {
                onSelect(_topCountries[i]);
                Navigator.pop(ctx);
              },
            );
          },
        );
      }
    );
  }

  void _showCityPicker() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final text = isLight ? const Color(0xFF0D2B1E) : const Color(0xFFEBF2EE);
    final bg = isLight ? const Color(0xFFF5F0E8) : const Color(0xFF080F0C);

    showModalBottomSheet(
      context: context, 
      backgroundColor: bg, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _hostCities.length,
          itemBuilder: (ctx, i) {
            return ListTile(
              title: Text(_hostCities[i], style: GoogleFonts.inter(color: text)),
              onTap: () {
                setState(() => _city = _hostCities[i]);
                Navigator.pop(ctx);
              },
            );
          },
        );
      }
    );
  }

  Widget _buildStep3(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final text = isLight ? const Color(0xFF0D2B1E) : const Color(0xFFEBF2EE);
    final card = isLight ? Colors.white : const Color(0xFF0D1A13);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Who do you want to meet?", 
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28, 
              fontWeight: FontWeight.bold, 
              color: text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select all that apply", 
            style: GoogleFonts.inter(
              fontSize: 14, 
              color: text.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),

          _buildMultiSelectCard("Dating & Romance", "Find a connection that lasts", LucideIcons.heart, const Color(0xFFE8437A)),
          const SizedBox(height: 12),
          _buildMultiSelectCard("Fan Friends", "Watch matches together", LucideIcons.trophy, const Color(0xFFF2C233)),
          const SizedBox(height: 12),
          _buildMultiSelectCard("Local Guide", "Show me your city", LucideIcons.map, const Color(0xFF4CB572)),
          
          const SizedBox(height: 32),
          _buildLabel(context, "FANS FROM WHICH COUNTRIES?"),
          Text(
            "Leave empty to meet everyone", 
            style: GoogleFonts.inter(
              fontSize: 13, 
              color: text.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          
          // Country selection button
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => CountrySelectorSheet(
                  selectedCountries: _countriesToMatch,
                  onSelect: (selected) {
                    setState(() => _countriesToMatch
                      ..clear()
                      ..addAll(selected));
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: text.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.globe, size: 20, color: Color(0xFFE8437A)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _countriesToMatch.isEmpty 
                          ? "Select nations..." 
                          : "${_countriesToMatch.length} nations selected",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: _countriesToMatch.isEmpty 
                            ? text.withValues(alpha: 0.5)
                            : text,
                        fontWeight: _countriesToMatch.isEmpty ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, 
                    size: 18, 
                    color: text.withValues(alpha: 0.3)
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Selected country chips (smaller Wrap)
          if (_countriesToMatch.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _countriesToMatch.map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8437A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8437A).withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE8437A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => _countriesToMatch.remove(c)),
                      child: const Icon(LucideIcons.x, size: 12, color: Color(0xFFE8437A)),
                    ),
                  ],
                ),
              )).toList(),
            ),
          const SizedBox(height: 32),

          _buildLabel(context, "YOUR EMAIL"),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(color: text),
            decoration: const InputDecoration(
              hintText: 'email@domain.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 24),
          
          _buildLabel(context, "CREATE PASSWORD"),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            onChanged: (v) => setState((){}),
            style: GoogleFonts.inter(color: text),
            decoration: const InputDecoration(
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 12),
          _buildPasswordStrengthBar(),
          const SizedBox(height: 24),

          // TERMS CHECKBOX
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _acceptedTerms,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                  activeColor: const Color(0xFF4CB572),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 12, 
                        color: text.withValues(alpha: 0.6)
                      ),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF4CB572),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF4CB572),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          _buildSignUpBtn(),
        ],
      ),
    );
  }

  Widget _buildMultiSelectCard(String title, String subtitle, IconData icon, Color activeColor) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final text = isLight ? const Color(0xFF0D2B1E) : const Color(0xFFEBF2EE);
    final card = isLight ? Colors.white : const Color(0xFF131F19);
    
    bool isSelected = _selectedIntentions.contains(title);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedIntentions.remove(title);
          } else {
            _selectedIntentions.add(title);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : text.withValues(alpha: 0.1), 
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(width: 4, height: 80, decoration: BoxDecoration(color: isSelected ? activeColor : Colors.transparent, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))),
            const SizedBox(width: 16),
            Icon(icon, size: 28, color: isSelected ? activeColor : activeColor.withValues(alpha: 0.5)),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: GoogleFonts.inter(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: isSelected ? activeColor : text,
                  ),
                ),
                Text(
                  subtitle, 
                  style: GoogleFonts.inter(
                    fontSize: 13, 
                    color: isSelected ? activeColor.withValues(alpha: 0.8) : text.withValues(alpha: 0.6),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthBar() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final text = isLight ? const Color(0xFF0D2B1E) : const Color(0xFFEBF2EE);
    int str = _getPasswordStrength(_passwordController.text);
    return Row(
      children: List.generate(4, (index) {
        Color c = text.withValues(alpha: 0.1);
        if (str > index) {
          if (str == 1) {
            c = Colors.red;
          } else if (str == 2) {
            c = Colors.orange;
          } else if (str == 3) {
            c = Colors.amber;
          } else {
            c = Colors.green;
          }
        }
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 4,
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
          ),
        );
      }),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text, 
        style: GoogleFonts.spaceMono(
          fontSize: 10, 
          color: const Color(0xFFE8437A), 
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildContinueBtn(bool enabled, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFE8437A),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE8437A).withValues(alpha: 0.1),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
        elevation: enabled ? 4 : 0,
      ),
      child: Text(
        "Continue →", 
        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSignUpBtn() {
    return Opacity(
      opacity: _acceptedTerms ? 1.0 : 0.5,
      child: ElevatedButton(
        onPressed: (_isLoading || !_acceptedTerms) ? null : _submitProfile,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFFE8437A),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE8437A).withValues(alpha: 0.1),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
          elevation: _acceptedTerms ? 4 : 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                "Create Account", 
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
