import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signin_screen.dart';

class EmailConfirmScreen extends StatefulWidget {
  final String email;

  const EmailConfirmScreen({super.key, required this.email});

  @override
  State<EmailConfirmScreen> createState() => _EmailConfirmScreenState();
}

class _EmailConfirmScreenState extends State<EmailConfirmScreen> {
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown > 0) {
        setState(() => _cooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_cooldown > 0) return;

    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Confirmation email sent!")),
        );
      }
      _startCooldown();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Error: $e")),
        );
      }
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // ICON
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF135E4B),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(Icons.mark_email_unread_outlined, color: Color(0xFF4CB572), size: 36),
                  ),
                ),
                const SizedBox(height: 24),

                // HEADING
                Text(
                  "Check your email",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),

                // SUBTEXT
                Text(
                  "We sent a confirmation link to",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
                ),
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 32),

                // INFO CARD
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF135E4B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CB572).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "HOW TO CONFIRM",
                        style: GoogleFonts.spaceMono(fontSize: 10, color: const Color(0xFF4CB572), letterSpacing: 2),
                      ),
                      const SizedBox(height: 12),
                      _buildStepRow(1, "Open the email from Turf&Ardor"),
                      const SizedBox(height: 12),
                      _buildStepRow(2, "Tap Confirm My Account"),
                      const SizedBox(height: 12),
                      _buildStepRow(3, "Come back here and sign in"),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // RESEND BUTTON
                OutlinedButton(
                  onPressed: _cooldown > 0 ? null : _resendEmail,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _cooldown > 0 ? const Color(0xFF4CB572).withValues(alpha: 0.3) : const Color(0xFF4CB572)),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _cooldown > 0 ? "Resend in ${_cooldown}s" : "Resend confirmation email",
                    style: GoogleFonts.inter(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600, 
                      color: _cooldown > 0 ? const Color(0xFF4CB572).withValues(alpha: 0.5) : const Color(0xFF4CB572)
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // BACK TO SIGN IN
                TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignInScreen())),
                  child: Text(
                    "Back to Sign In",
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.4)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(int number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF4CB572).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            number.toString(),
            style: GoogleFonts.spaceMono(fontSize: 11, color: const Color(0xFF4CB572)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }
}
