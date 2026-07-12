import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../shared/widgets/grid_painter.dart';
import '../../shared/widgets/safetext_app_bar.dart';
import '../../shared/widgets/tool_option_card.dart';

class SteganographyHomeScreen extends StatefulWidget {
  const SteganographyHomeScreen({super.key});

  @override
  State<SteganographyHomeScreen> createState() => _SteganographyHomeScreenState();
}

class _SteganographyHomeScreenState extends State<SteganographyHomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: SafeTextAppBar(
        scrollController: _scrollController,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: GridBackground(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 150),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(scheme),
                  const SizedBox(height: 32),
                  const _SectionHeader(title: 'AVAILABLE PROTOCOLS', icon: Icons.layers_outlined),
                  const SizedBox(height: 16),
                  ToolOptionCard(
                    title: 'GHOST EMBEDDING',
                    description: 'Advanced pixel-level concealment using scattered bit insertion. Extremely difficult to detect with standard steganalysis.',
                    iconColor: AppColors.green,
                    icon: Icons.blur_on_rounded,
                    tags: const ['STEALTH', 'HIGH SECURITY'],
                    onTap: () => context.push(AppRoutes.stegoLsbText),
                  ),
                  const SizedBox(height: 16),
                  ToolOptionCard(
                    title: 'ARMOR WRAPPER',
                    description: 'Redundant LSB embedding designed to survive minor image compression and social media processing.',
                    iconColor: AppColors.blue,
                    icon: Icons.shield_rounded,
                    tags: const ['ROBUST', 'REDUNANT'],
                    onTap: () => context.push(AppRoutes.stegoLsbDes),
                  ),
                  const SizedBox(height: 32),
                  _buildSecurityWarning(scheme),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: scheme.outline, width: 2.0),
          ),
          child: Icon(Icons.image_search_rounded, color: scheme.primary, size: 28),
        ),
        const SizedBox(height: 24),
        Text(
          'HIDE MESSAGES INSIDE IMAGES',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: scheme.onSurface,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose a concealment method. Both hide text inside ordinary pixels — pick the one that matches how much protection you need.'.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityWarning(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.outline, width: 2.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'NEITHER OF THESE MODULES MATCHES SAFETEXT\'S CORE ENCODER IN STRENGTH. FOR ANYTHING SENSITIVE, USE ENCODE FROM THE HOME SCREEN (AES-256-GCM + ARGON2ID).',
              style: TextStyle(
                fontFamily: 'Roboto Mono',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }
}
