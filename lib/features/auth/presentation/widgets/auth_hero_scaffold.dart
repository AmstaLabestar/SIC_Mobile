import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_gradients.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/sic_logo.dart';

/// Ossature premium des ecrans d'authentification : un en-tete degrade de marque
/// (logo + titre + sous-titre en blanc) surmonte d'une feuille blanche aux coins
/// arrondis qui chevauche legerement le degrade, ou se loge le formulaire.
///
/// Partage par login et inscription pour une experience unifiee et coherente
/// avec les ecrans OTP/PIN (memes codes visuels).
class AuthHeroScaffold extends StatelessWidget {
  const AuthHeroScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
    this.onBack,
  });

  final String title;

  /// Rendu en blanc (DefaultTextStyle) : passer un simple `Text` sans couleur,
  /// ou un `AnimatedSwitcher` pour un sous-titre qui s'adapte (cf. inscription).
  final Widget subtitle;
  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _Hero(
            title: title,
            subtitle: subtitle,
            showBack: showBack,
            onBack: onBack,
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.title,
    required this.subtitle,
    required this.showBack,
    required this.onBack,
  });

  final String title;
  final Widget subtitle;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
          child: FadeSlideIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 32,
                  width: double.infinity,
                  child: showBack
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: AppColors.onPrimary),
                            onPressed: onBack,
                          ),
                        )
                      : null,
                ),
                const SicLogo(size: 42),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: AppTextStyles.titleLarge
                      .copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                DefaultTextStyle(
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.onPrimary.withOpacity(0.88),
                  ),
                  textAlign: TextAlign.center,
                  child: subtitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
