import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'signin_screen.dart';
import '../../../core/constants/colors.dart';

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
          const SnackBar(
            content: Text("Confirmation email sent!"),
            backgroundColor: TurfArdorColors.emeraldForest,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _startCooldown();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text("Error: $e"),
             backgroundColor: TurfArdorColors.error,
             behavior: SnackBarBehavior.floating,
           ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgColor = isLight ? const Color(0xFFFBF8F3) : TurfArdorColors.backgroundDark;
    final textColor = isLight ? TurfArdorColors.textPrimaryLight : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomCenter,
            radius: 1.2,
            colors: [
              TurfArdorColors.emeraldForest.withValues(alpha: isLight ? 0.05 : 0.2),
              bgColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                
                // ELEGANT ICON
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : TurfArdorColors.darkCard,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: TurfArdorColors.emeraldForest.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.mailCheck, 
                      color: TurfArdorColors.emeraldForest, 
                      size: 38
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),

                // SERIF HEADING
                Text(
                  "Check your email",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold, 
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                
                const SizedBox(height: 12),

                // SUBTEXT
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 15, 
                        color: textColor.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: "We've sent a secure confirmation link to\n"),
                        TextSpan(
                          text: widget.email,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),

                // STEPS CARD
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : TurfArdorColors.darkCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isLight ? const Color(0xFFE8DDD0) : TurfArdorColors.emeraldForest.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildStepRow(1, "Open your inbox"),
                      const Padding(
                        padding: EdgeInsets.only(left: 12, top: 4, bottom: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(height: 16, child: VerticalDivider(width: 1)),
                        ),
                      ),
                      _buildStepRow(2, "Tap 'Confirm My Account'"),
                      const Padding(
                        padding: EdgeInsets.only(left: 12, top: 4, bottom: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(height: 16, child: VerticalDivider(width: 1)),
                        ),
                      ),
                      _buildStepRow(3, "Return here to signed in"),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),

                // PRIMARY ACTION
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _cooldown > 0 ? null : _resendEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TurfArdorColors.emeraldForest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      _cooldown > 0 ? "Resend in ${_cooldown}s" : "Resend Email",
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // BACK BUTTON
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (_) => const SignInScreen())
                  ),
                  child: Text(
                    "Back to Sign In",
                    style: GoogleFonts.inter(
                      fontSize: 14, 
                      color: textColor.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(int number, String text) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? TurfArdorColors.textPrimaryLight : Colors.white;

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: TurfArdorColors.emeraldForest.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: GoogleFonts.spaceMono(
                fontSize: 11, 
                fontWeight: FontWeight.bold,
                color: TurfArdorColors.emeraldForest,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14, 
            color: textColor.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
