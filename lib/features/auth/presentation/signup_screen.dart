import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'email_confirm_screen.dart';

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
    // Basic final validations
    if (_emailController.text.isEmpty || _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a valid email and password (min 6 chars)')));
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
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
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        if (response.user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EmailConfirmScreen(
                email: _emailController.text.trim()
              )
            )
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign up failed. Please try again.')));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  int _getPasswordStrength(String password) {
    int s = 0;
    if (password.length >= 8) s++;
    if (password.contains(RegExp(r'[A-Z]'))) s++;
    // ignore: valid_regexps
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[!@#\$&*~]'))) s++;
    return s == 0 && password.isNotEmpty ? 1 : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080F0C),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                   _buildStep1(),
                   _buildStep2(),
                   _buildStep3(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                  color: active ? const Color(0xFF4CB572) : Colors.white.withValues(alpha: 0.2),
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
                style: GoogleFonts.spaceMono(fontSize: 11, color: const Color(0xFF4CB572)),
              ),
            )
          else
            const SizedBox(width: 48), // Balance alignment
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: (_currentPage + 1) / 3,
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CB572)),
      minHeight: 2,
    );
  }
  
  // --- STEP 1 ---
  Widget _buildStep1() {
    bool canContinue = _nameController.text.isNotEmpty && 
                       (int.tryParse(_ageController.text) ?? 0) >= 18 && 
                       _selectedGender != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Tell us about you", style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text("You can always change this later", style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.4))),
          const SizedBox(height: 32),

          // A) Photo
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3D28),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF4CB572).withValues(alpha: 0.5), width: 2, style: BorderStyle.solid), // dashed isn't native easily, fallback solid
                      image: _profileImageBytes != null 
                        ? DecorationImage(image: MemoryImage(_profileImageBytes!), fit: BoxFit.cover) 
                        : null,
                    ),
                    child: _profileImageBytes == null ? const Icon(Icons.camera_alt, color: Color(0xFF4CB572), size: 32) : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text("Add Photo (optional)", style: GoogleFonts.spaceMono(fontSize: 10, color: const Color(0xFF9BB3AF))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // B) Name
          _buildLabel("YOUR NAME"),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => setState((){}),
            decoration: _inputDecoration("What do people call you?"),
          ),
          const SizedBox(height: 24),

          // C) Age
          _buildLabel("YOUR AGE"),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => setState((){}),
            decoration: _inputDecoration("Must be 18+"),
          ),
          const SizedBox(height: 24),

          // D) Gender
          _buildLabel("GENDER"),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genders.map((g) {
              final isSelected = _selectedGender == g;
              return GestureDetector(
                onTap: () => setState(() => _selectedGender = g),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF135E4B) : const Color(0xFF152B1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? const Color(0xFF4CB572) : const Color(0xFF1E4A33)),
                  ),
                  child: Text(g, style: GoogleFonts.inter(fontSize: 14, color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5))),
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

  // --- STEP 2 ---
  Widget _buildStep2() {
    bool canContinue = _nationality != null && _teamSupported != null && (!_isLocal || _city != null);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Your football identity", style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text("This is how fans find you", style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.4))),
          const SizedBox(height: 32),

          _buildLabel("YOUR NATIONALITY"),
          GestureDetector(
            onTap: () => _showCountryPicker((val) => setState(() => _nationality = val)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF152B1E), borderRadius: BorderRadius.circular(12)),
              child: Text(_nationality ?? "Select Nationality", style: GoogleFonts.inter(color: _nationality != null ? Colors.white : Colors.white.withValues(alpha: 0.5))),
            ),
          ),
          const SizedBox(height: 24),

          _buildLabel("TEAM YOU SUPPORT"),
          GestureDetector(
            onTap: () => _showCountryPicker((val) => setState(() => _teamSupported = val)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF152B1E), borderRadius: BorderRadius.circular(12)),
              child: Text(_teamSupported ?? "Select Team", style: GoogleFonts.inter(color: _teamSupported != null ? Colors.white : Colors.white.withValues(alpha: 0.5))),
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(child: _buildToggleCard(true, "🏠", "I'm a Local", "I live here")),
              const SizedBox(width: 16),
              Expanded(child: _buildToggleCard(false, "✈️", "I'm Visiting", "I'm a tourist")),
            ],
          ),
          
          if (_isLocal) ...[
            const SizedBox(height: 32),
            _buildLabel("YOUR CITY"),
            GestureDetector(
              onTap: () => _showCityPicker(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF152B1E), borderRadius: BorderRadius.circular(12)),
                child: Text(_city ?? "Select Host City", style: GoogleFonts.inter(color: _city != null ? Colors.white : Colors.white.withValues(alpha: 0.5))),
              ),
            ),
          ],
          
          const SizedBox(height: 48),
          _buildContinueBtn(canContinue, _nextStep),
        ],
      ),
    );
  }
  
  Widget _buildToggleCard(bool isLocalValue, String icon, String title, String sub) {
    bool isSelected = _isLocal == isLocalValue;
    return GestureDetector(
      onTap: () => setState(() {
        _isLocal = isLocalValue;
        if (!_isLocal) _city = null; 
      }),
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF135E4B) : const Color(0xFF152B1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF4CB572) : const Color(0xFF1E4A33), width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Text(sub, style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker(Function(String) onSelect) {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF080F0C), builder: (ctx) {
      return ListView.builder(
        itemCount: _topCountries.length,
        itemBuilder: (ctx, i) {
          return ListTile(
            title: Text(_topCountries[i], style: const TextStyle(color: Colors.white)),
            onTap: () {
              onSelect(_topCountries[i]);
              Navigator.pop(ctx);
            },
          );
        },
      );
    });
  }

  void _showCityPicker() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF080F0C), builder: (ctx) {
      return ListView.builder(
        itemCount: _hostCities.length,
        itemBuilder: (ctx, i) {
          return ListTile(
            title: Text(_hostCities[i], style: const TextStyle(color: Colors.white)),
            onTap: () {
              setState(() => _city = _hostCities[i]);
              Navigator.pop(ctx);
            },
          );
        },
      );
    });
  }

  // --- STEP 3 ---
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Who do you want to meet?", style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text("Select all that apply", style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.4))),
          const SizedBox(height: 32),

          _buildMultiSelectCard("Dating & Romance", "Find a connection that lasts", "❤️"),
          const SizedBox(height: 12),
          _buildMultiSelectCard("Fan Friends", "Watch matches together", "⚽"),
          const SizedBox(height: 12),
          _buildMultiSelectCard("Local Guide", "Show me your city", "🗺️"),
          
          const SizedBox(height: 32),
          _buildLabel("FANS FROM WHICH COUNTRIES?"),
          Text("Leave empty to meet everyone", style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _topCountries.map((c) {
               bool isSelected = _countriesToMatch.contains(c);
               return GestureDetector(
                 onTap: () {
                   setState(() {
                     if (isSelected) {
                       _countriesToMatch.remove(c);
                     } else {
                       _countriesToMatch.add(c);
                     }
                   });
                 },
                 child: Container(
                   height: 36,
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                   decoration: BoxDecoration(
                     color: isSelected ? const Color(0xFF4CB572) : const Color(0xFF152B1E),
                     borderRadius: BorderRadius.circular(18),
                   ),
                   alignment: Alignment.center,
                   child: Text(c, style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                 )
               );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {}, // For 195 list expansion
              child: const Text("+ Add more countries", style: TextStyle(color: Color(0xFF4CB572))),
            )
          ),
          
          const SizedBox(height: 32),
          _buildLabel("YOUR EMAIL"),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration("email@domain.com"),
          ),
          const SizedBox(height: 24),
          
          _buildLabel("CREATE PASSWORD"),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            onChanged: (v) => setState((){}),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration("Minimum 6 characters"),
          ),
          const SizedBox(height: 12),
          _buildPasswordStrengthBar(),
          
          const SizedBox(height: 48),
          _buildSignUpBtn(),
        ],
      ),
    );
  }

  Widget _buildMultiSelectCard(String title, String subtitle, String icon) {
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
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF135E4B) : const Color(0xFF152B1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF4CB572) : const Color(0xFF1E4A33), width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(width: 3, height: 80, color: isSelected ? const Color(0xFF4CB572) : Colors.transparent),
            const SizedBox(width: 16),
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
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
        Color c = Colors.white.withValues(alpha: 0.08);
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

  // --- HELPERS ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: GoogleFonts.spaceMono(fontSize: 10, color: const Color(0xFF4CB572), letterSpacing: 2)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      fillColor: const Color(0xFF152B1E),
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4CB572))),
    );
  }
  
  Widget _buildContinueBtn(bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          height: 56, alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xFF135E4B), Color(0xFF4CB572)]),
          ),
          child: Text("Continue →", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildSignUpBtn() {
    return InkWell(
      onTap: _isLoading ? null : _submitProfile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56, alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Color(0xFF135E4B), Color(0xFF4CB572)]),
        ),
        child: _isLoading 
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text("Create My Profile 🎉", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}
