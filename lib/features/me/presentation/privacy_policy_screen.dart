import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fifalove_mobile/core/constants/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? FifaColors.backgroundLight : FifaColors.backgroundDark;
    final text = isLight ? FifaColors.textPrimaryLight : FifaColors.textPrimaryDark;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(LucideIcons.chevronLeft, color: text),
              onPressed: () => Navigator.pop(context),
            ),
            floating: true,
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'PRIVACY POLICY',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: FifaColors.accent,
                ),
              ),
              centerTitle: true,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection('1. Introduction', 
                  'Welcome to FIFA LOVE. We value your privacy and are committed to protecting your personal data. This policy explains how we handle your information when you use our World Cup 2026 dating platform.'),
                _buildSection('2. Data Collection', 
                  'We collect information you provide directly to us, such as your profile details, World Cup interests, and match preferences. We also collect automated data about your usage of the application to improve our services.'),
                _buildSection('3. How We Use Data', 
                  'Your data is primarily used to facilitate matches between football fans. We use your location (if shared) to show nearby fans and your favorite team to calculate compatibility scores.'),
                _buildSection('4. Security', 
                  'We implement premium security standards to protect your data. All communication is encrypted, and your private contact information is never shared without your consent.'),
                const SizedBox(height: 60),
                Center(
                  child: Text(
                    'Last Updated: June 2026',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: FifaColors.mutedTextLight.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
