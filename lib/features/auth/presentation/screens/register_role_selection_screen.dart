import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/sic_network_globe.dart';

class RegisterRoleSelectionScreen extends StatelessWidget {
  const RegisterRoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Globe & En-tête
                FadeSlideIn(
                  child: Column(
                    children: [
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SicNetworkGlobe(size: 280),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Création de compte',
                        style: AppTextStyles.displayLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choisissez votre profil pour commencer l\'inscription sur SIC',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Option 1 : Agent
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: _RoleCard(
                    title: 'Compte Agent',
                    subtitle:
                        'Gérez vos SIM, le float, le rééquilibrage de vos puces et effectuez vos opérations de compensation facilement.',
                    icon: Icons.storefront_rounded,
                    iconColor:
                        const Color(0xFFFF7900), // Orange Money brand/vibrant
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.go('/register/agent');
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Option 2 : Client/Utilisateur
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: _RoleCard(
                    title: 'Compte Client',
                    subtitle:
                        'Envoyez, recevez et transférez de l\'argent vers vos proches instantanément d\'un réseau à un autre.',
                    icon: Icons.person_outline_rounded,
                    iconColor: const Color(0xFF1A73E8), // Wave blue/vibrant
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.go('/register/client');
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Pied de page
                FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text.rich(
                      TextSpan(
                        text: 'Vous avez déjà un compte ? ',
                        style: AppTextStyles.caption,
                        children: [
                          TextSpan(
                            text: 'Se connecter',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = widget.iconColor.withOpacity(0.04);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: _isHovered ? hoverColor : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isPressed
                    ? widget.iconColor
                    : (_isHovered
                        ? widget.iconColor.withOpacity(0.7)
                        : const Color(0xFFE2E8F0)),
                width: (_isPressed || _isHovered) ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? widget.iconColor.withOpacity(0.1)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: _isHovered ? 20 : 16,
                  offset: _isHovered ? const Offset(0, 8) : const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 28,
                    color: widget.iconColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _isHovered ? widget.iconColor : AppColors.textTertiary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
