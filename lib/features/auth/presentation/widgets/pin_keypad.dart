import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Affiche l'avancement de saisie d'un PIN sous forme de pastilles.
///
/// [count] pastilles remplies sur [max] emplacements. [error] colore les
/// pastilles en rouge. [onLight] adapte les couleurs sur fond sombre/degrade.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.count,
    required this.max,
    this.error = false,
    this.onLight = false,
  });

  final int count;
  final int max;
  final bool error;
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final fill = error
        ? AppColors.danger
        : (onLight ? AppColors.onPrimary : AppColors.primary);
    final empty = onLight
        ? AppColors.onPrimary.withOpacity(0.35)
        : AppColors.border;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(max, (i) {
        final filled = i < count;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 9),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? fill : Colors.transparent,
            border: Border.all(color: filled ? fill : empty, width: 1.6),
          ),
        );
      }),
    );
  }
}

/// Pave numerique reutilisable et responsive pour la saisie d'un PIN.
///
/// Composant controle (sans etat) : il notifie [onDigit] / [onBackspace] et
/// dimensionne ses touches selon la place disponible (largeur ET hauteur) pour
/// ne jamais deborder. A placer dans une zone a hauteur bornee (ex: `Expanded`).
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final byWidth = (constraints.maxWidth - 2 * gap) / 3;
        final byHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - 4 * gap) / 4
            : byWidth;
        final size = math.min(byWidth, byHeight).clamp(40.0, 72.0);

        Widget digit(String d) => _KeyButton(
              size: size,
              onTap: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      onDigit(d);
                    }
                  : null,
              hasBackground: true,
              child: Text(
                d,
                style: AppTextStyles.titleLarge.copyWith(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            );

        Widget row(List<Widget> children) => Padding(
              padding: const EdgeInsets.symmetric(vertical: gap / 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: children,
              ),
            );

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
            ])
              row(r.map(digit).toList()),
            row([
              SizedBox(width: size * 1.1, height: size),
              digit('0'),
              _KeyButton(
                size: size,
                onTap: enabled
                    ? () {
                        HapticFeedback.selectionClick();
                        onBackspace();
                      }
                    : null,
                hasBackground: false,
                child: Text(
                  'Effacer',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ]),
          ],
        );
      },
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.child,
    required this.size,
    this.onTap,
    this.hasBackground = true,
  });

  final Widget child;
  final double size;
  final VoidCallback? onTap;
  final bool hasBackground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.1,
      height: size,
      child: Material(
        color: hasBackground ? AppColors.primaryBg : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}
