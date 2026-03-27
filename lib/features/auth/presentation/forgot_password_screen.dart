import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_config.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.fifalove.app://reset',
      );
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFE83535)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Something went wrong — please try again'),
              backgroundColor: Color(0xFFE83535)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: Colors.white.withValues(alpha: 0.6), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Icon
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFF135E4B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_reset_outlined,
                        size: 32, color: Color(0xFF4CB572)),
                  ),
                ),

                const SizedBox(height: 24),

                // Heading
                Text(
                  'Reset Password',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtext
                Text(
                  'Enter your email and we will\nsend you a reset link',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),

                const SizedBox(height: 40),

                // Email label
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'EMAIL',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: const Color(0xFF4CB572),
                      letterSpacing: 2,
                    ),
                  ),
                ),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'your@email.com',
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    fillColor: const Color(0xFF152B1E),
                    filled: true,
                    prefixIcon: const Icon(Icons.mail_outline,
                        color: Color(0xFF4CB572)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF4CB572), width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Send button or success state
                if (_sent)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF135E4B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            const Color(0xFF4CB572).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 20, color: Color(0xFF4CB572)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reset link sent! Check your inbox.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    onTap: _isLoading ? null : _sendReset,
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
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Send Reset Link',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Back to sign in
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Back to Sign In',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF4CB572),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
