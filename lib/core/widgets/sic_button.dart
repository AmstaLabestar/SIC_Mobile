import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum SicButtonVariant { primary, secondary, ghost }

class SicButton extends StatelessWidget {
  const SicButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = SicButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final SicButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    return Semantics(
      button: true,
      enabled: effectiveOnPressed != null,
      label: label,
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: switch (variant) {
          SicButtonVariant.primary => ElevatedButton(
              onPressed: effectiveOnPressed,
              child: _ButtonContent(label: label, isLoading: isLoading),
            ),
          SicButtonVariant.secondary => OutlinedButton(
              onPressed: effectiveOnPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _ButtonContent(
                label: label,
                isLoading: isLoading,
                loaderColor: AppColors.primary,
              ),
            ),
          SicButtonVariant.ghost => TextButton(
              onPressed: effectiveOnPressed,
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: _ButtonContent(
                label: label,
                isLoading: isLoading,
                loaderColor: AppColors.primary,
              ),
            ),
        },
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.isLoading,
    this.loaderColor = AppColors.surface,
  });

  final String label;
  final bool isLoading;
  final Color loaderColor;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(
          color: loaderColor,
          strokeWidth: 2,
        ),
      );
    }

    return Text(label);
  }
}
