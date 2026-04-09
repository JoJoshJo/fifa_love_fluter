import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: Color(0xFF4CB572),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Widget _buildLabel(BuildContext context, String text) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.spaceMono(
          fontSize: 10,
          color: isLight ? TurfArdorColors.emeraldForest : TurfArdorColors.emeraldSpring,
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              TurfArdorColors.emeraldForest.withValues(alpha: isLight ? 0.05 : 0.2),
            ],
            stops: const [0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Set New Password",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.displayLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Choose a secure password to protect your account.",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 48),

                // NEW PASSWORD
                _buildLabel(context, "NEW PASSWORD"),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: "••••••••",
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: isLight ? TurfArdorColors.emeraldForest : TurfArdorColors.emeraldSpring,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // CONFIRM PASSWORD
                _buildLabel(context, "CONFIRM PASSWORD"),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: "••••••••",
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: isLight ? TurfArdorColors.emeraldForest : TurfArdorColors.emeraldSpring,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // UPDATE BUTTON
                ElevatedButton(
                  onPressed: _loading ? null : _updatePassword,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Update Password"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
