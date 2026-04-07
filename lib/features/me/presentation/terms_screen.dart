import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fifalove_mobile/core/constants/colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? TurfArdorColors.backgroundLight : TurfArdorColors.backgroundDark;
    final text = isLight ? TurfArdorColors.textPrimaryLight : TurfArdorColors.textPrimaryDark;

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
                'TERMS OF SERVICE',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: TurfArdorColors.accent,
                ),
              ),
              centerTitle: true,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection('1. Engagement Rules', 
                  'Turf&Ardor is a community for passionate football fans. We reserve the right to remove any user found engaging in harassment, discrimination, or abusive behavior.'),
                _buildSection('2. Intellectual Property', 
                  'All FIFA trademarks, logos, and World Cup assets are the property of their respective owners. This application is an independent community project and is not officially affiliated with FIFA.'),
                _buildSection('3. Account Eligibility', 
                  'Users must be at least 18 years old to create a profile. By using the service, you represent that you meet this requirement.'),
                _buildSection('4. Premium Access', 
                  'We offer premium features to enhance your matching experience. All transactions are subject to standard app store terms.'),
                const SizedBox(height: 60),
                Center(
                  child: Text(
                    'Last Updated: June 2026',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: TurfArdorColors.mutedTextLight.withValues(alpha: 0.5),
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
