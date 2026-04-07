import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'email_confirm_screen.dart';
import 'widgets/country_selector_sheet.dart';
import '../../../core/constants/colors.dart';
import '../../../core/supabase/supabase_config.dart';
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
  final List<String> _topCountries = ["Brazil", "France", "Argentina", "USA", "England", "Germany", "Spain", "Portugal", "Morocco", "Japan", "Nigeria", "Mexico", "Colombia", "Senegal", "Australia", "South Korea", "Netherlands", "Italy", "Belgium", "Canada"];
  final List<String> _hostCities = ["Dallas", "Los Angeles", "New York/New Jersey", "San Francisco Bay Area", "Seattle", "Kansas City", "Boston", "Miami", "Atlanta", "Houston", "Philadelphia", "Vancouver", "Toronto", "Guadalajara", "Mexico City", "Monterrey"];

  // STEP 3 STATE
  final List<String> _selectedIntentions = [];
  final List<String> _countriesToMatch = [];
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a valid email and password (min 6 chars)'),
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // 1. Authenticate with Supabase
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
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
      
      if (user != null) {
        // 2. Immediately create the database profile record
        // This prevents the user from being stuck in the "Setup" screen later.
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

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EmailConfirmScreen(email: email)
            )
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign up failed. Please try again.'),
              behavior: SnackBarBehavior.floating,
            )
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        String msg = e.message;
        if (msg.contains('already registered') || msg.contains('already_exists')) {
          msg = "This email is already registered. Please login instead.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFFE8437A),
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An unexpected error occurred. Please try again.'),
            backgroundColor: const Color(0xFFE8437A),
            behavior: SnackBarBehavior.floating,
          )
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
    final theme = Theme.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
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
                  color: active ? TurfArdorColors.emeraldSpring : theme.dividerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          if (_currentPage < 2)
            TextButton(
              onPressed: _nextStep,
              child: Text(
                'Skip',
                style: GoogleFonts.spaceMono(
                  fontSize: 11, 
                  color: const Color(0xFFE8437A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const SizedBox(width: 48), 
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return LinearProgressIndicator(
      value: (_currentPage + 1) / 3,
      backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.05),
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE8437A)),
      minHeight: 2,
    );
  }
  
  Widget _buildStep1(BuildContext context) {
    final theme = Theme.of(context);
    bool canContinue = _nameController.text.isNotEmpty && 
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
              color: theme.textTheme.displayLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You can always change this later", 
            style: GoogleFonts.inter(
              fontSize: 14, 
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
                  "Add Photo (optional)", 
                  style: GoogleFonts.spaceMono(
                    fontSize: 11, 
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
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
            style: theme.textTheme.bodyLarge,
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
            style: theme.textTheme.bodyLarge,
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
                    color: isSelected ? const Color(0xFFE8437A) : theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFE8437A) : theme.dividerColor.withValues(alpha: 0.2),
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
                      color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
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
    final theme = Theme.of(context);
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
              color: theme.textTheme.displayLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This is how fans find you", 
            style: GoogleFonts.inter(
              fontSize: 14, 
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),

          _buildLabel(context, "YOUR NATIONALITY"),
          GestureDetector(
            onTap: () => _showCountryPicker((val) => setState(() => _nationality = val)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor, 
                borderRadius: BorderRadius.circular(12),
                border: _nationality != null 
                  ? Border.all(color: TurfArdorColors.emeraldSpring.withValues(alpha: 0.5))
                  : null,
              ),
              child: Row(
                children: [
                  Text(
                    _nationality ?? "Select Nationality", 
                    style: GoogleFonts.inter(
                      color: _nationality != null ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                      fontWeight: _nationality != null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.expand_more, color: theme.textTheme.bodySmall?.color),
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
                color: theme.inputDecorationTheme.fillColor, 
                borderRadius: BorderRadius.circular(12),
                border: _teamSupported != null 
                  ? Border.all(color: TurfArdorColors.emeraldSpring.withValues(alpha: 0.5))
                  : null,
              ),
              child: Row(
                children: [
                  Text(
                    _teamSupported ?? "Select Team", 
                    style: GoogleFonts.inter(
                      color: _teamSupported != null ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                      fontWeight: _teamSupported != null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.expand_more, color: theme.textTheme.bodySmall?.color),
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
                  color: theme.inputDecorationTheme.fillColor, 
                  borderRadius: BorderRadius.circular(12),
                  border: _city != null 
                    ? Border.all(color: TurfArdorColors.emeraldSpring.withValues(alpha: 0.5))
                    : null,
                ),
                child: Row(
                  children: [
                    Text(
                      _city ?? "Select Host City", 
                      style: GoogleFonts.inter(
                        color: _city != null ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                        fontWeight: _city != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.expand_more, color: theme.textTheme.bodySmall?.color),
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
    final theme = Theme.of(context);
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
          color: isSelected ? TurfArdorColors.emeraldForest : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? TurfArdorColors.emeraldSpring : theme.dividerColor.withValues(alpha: 0.1), 
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
                color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color, 
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub, 
              style: GoogleFonts.inter(
                fontSize: 12, 
                color: isSelected ? Colors.white.withValues(alpha: 0.7) : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker(Function(String) onSelect) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context, 
      backgroundColor: theme.scaffoldBackgroundColor, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _topCountries.length,
          itemBuilder: (ctx, i) {
            return ListTile(
              title: Text(_topCountries[i], style: theme.textTheme.bodyLarge),
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
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context, 
      backgroundColor: theme.scaffoldBackgroundColor, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _hostCities.length,
          itemBuilder: (ctx, i) {
            return ListTile(
              title: Text(_hostCities[i], style: theme.textTheme.bodyLarge),
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
    final theme = Theme.of(context);
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
              color: theme.textTheme.displayLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select all that apply", 
            style: GoogleFonts.inter(
              fontSize: 14, 
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
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
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
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
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.1),
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
                            ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)
                            : theme.textTheme.bodyLarge?.color,
                        fontWeight: _countriesToMatch.isEmpty ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, 
                    size: 18, 
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)
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
            style: theme.textTheme.bodyLarge,
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
            style: theme.textTheme.bodyLarge,
            decoration: const InputDecoration(
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 12),
          _buildPasswordStrengthBar(),
          
          const SizedBox(height: 48),
          _buildSignUpBtn(),
        ],
      ),
    );
  }

  Widget _buildMultiSelectCard(String title, String subtitle, IconData icon, Color activeColor) {
    final theme = Theme.of(context);
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
          color: isSelected ? activeColor.withValues(alpha: 0.1) : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : theme.dividerColor.withValues(alpha: 0.1), 
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
                    color: isSelected ? activeColor : theme.textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  subtitle, 
                  style: GoogleFonts.inter(
                    fontSize: 13, 
                    color: isSelected ? activeColor.withValues(alpha: 0.8) : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
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
    int str = _getPasswordStrength(_passwordController.text);
    return Row(
      children: List.generate(4, (index) {
        Color c = Theme.of(context).dividerColor.withValues(alpha: 0.1);
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
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitProfile,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFE8437A),
        disabledBackgroundColor: const Color(0xFFE8437A).withValues(alpha: 0.1),
      ),
      child: _isLoading 
        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
        : Text("Create My Profile", 
             style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}
