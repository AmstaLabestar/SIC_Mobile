import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'operator_logo.dart';

/// Grille 2 colonnes de selection d'operateur. Widget pur : la liste
/// d'operateurs est passee en parametre (cf. [kAvailableOperators]).
class OperatorSelector extends StatelessWidget {
  const OperatorSelector({
    super.key,
    required this.operators,
    required this.selectedOperatorCode,
    required this.onSelected,
  });

  final Map<String, String> operators;
  final String selectedOperatorCode;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final entries = operators.entries.toList();

    return GridView.builder(
      itemCount: entries.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 84,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isSelected = entry.key == selectedOperatorCode;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onSelected(entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.05)
                  : AppColors.surface,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.8 : 1,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OperatorLogo(
                        operatorCode: entry.key,
                        size: 36,
                        shape: OperatorLogoShape.roundedSquare,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.value,
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
