import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/sic_error_widget.dart';
import '../../../../core/widgets/sic_loading.dart';
import '../providers/alert_provider.dart';
import '../widgets/alert_config_tile.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(alertNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: state.when(
          loading: () => const SicLoading(),
          error: (error, _) => SicErrorWidget(
            error: error,
            onRetry: () => ref.read(alertNotifierProvider.notifier).refresh(),
          ),
          data: (configs) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            itemCount: configs.length + 2,
            separatorBuilder: (context, index) {
              return const SizedBox(height: AppSpacing.md);
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xs),
                  child: Text(
                    'Alertes solde',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                );
              }

              if (index == 1) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'Configurez les seuils pour être prévenu avant qu\'une puce ne bloque une opération.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                );
              }

              return AlertConfigTile(config: configs[index - 2]);
            },
          ),
        ),
      ),
    );
  }
}
