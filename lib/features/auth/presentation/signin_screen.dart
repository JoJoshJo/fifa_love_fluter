import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'setup_screen.dart';
import '../../main/presentation/main_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (mounted && response.user != null) {
        try {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('nationality')
              .eq('id', response.user!.id)
              .maybeSingle();

          if (mounted) {
            if (profile == null || profile['nationality'] == null) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SetupScreen()));
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
            }
          }
        } catch (e) {
          // If profiles table doesn't exist or query fails, we route to SetupScreen for testing
          debugPrint("Profiles query failed: $e");
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SetupScreen()));
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        String msg = "Something went wrong — please try again";
        if (e.message.contains("Email not confirmed")) {
          msg = "Please check your inbox and confirm your email";
        } else if (e.message.toLowerCase().contains("invalid login credentials")) {
          msg = "Incorrect email or password — please try again";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Something went wrong — please try again")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.spaceMono(fontSize: 10, color: const Color(0xFF4CB572), letterSpacing: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080F0C),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomCenter,
            radius: 1.5,
            colors: [
              const Color(0xFF135E4B).withValues(alpha: 0.4),
              const Color(0xFF080F0C),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: Colors.white.withValues(alpha: 0.6), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Welcome back",
                  style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  "Sign in to continue",
                  style: GoogleFonts.inter(fontSize: 15, color: Colors.white.withValues(alpha: 0.45)),
                ),
                const SizedBox(height: 40),
                
                // EMAIL
                _buildLabel("EMAIL"),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "your@email.com",
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    fillColor: const Color(0xFF152B1E),
                    filled: true,
                    prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF4CB572)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4CB572), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),
                
                // PASSWORD
                _buildLabel("PASSWORD"),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "••••••••",
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    fillColor: const Color(0xFF152B1E),
                    filled: true,
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4CB572)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4CB572), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),
                
                // FORGOT PASS
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                    child: Text(
                      "Forgot password?",
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4CB572)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // SIGN IN BUTTON
                InkWell(
                  onTap: _isLoading ? null : _signIn,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF135E4B), Color(0xFF4CB572)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text("Sign In", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
                
                // DIVIDER
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("or", style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.3))),
                    ),
                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
                  ],
                ),
                const SizedBox(height: 24),
                
                // CREATE ACCOUNT
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.5))),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                      child: Text("Create Account", style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF4CB572))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
