import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_failure.dart';
import '../../../transactions/presentation/widgets/pin_prompt_sheet.dart';
import '../../domain/entities/float_operation.dart';
import '../providers/operation_provider.dart';
import '../../../../core/widgets/operator_logo.dart';

const _operators = ['ORANGE', 'MOOV', 'TELECEL', 'MTN'];

/// Écran générique d'opération overlay (conversion / transfert / airtime),
/// branché sur la machine à états backend (`/api/operations/`).
class OperationScreen extends ConsumerStatefulWidget {
  const OperationScreen({super.key, required this.type, required this.title});

  final OperationType type;
  final String title;

  @override
  ConsumerState<OperationScreen> createState() => _OperationScreenState();
}

class _OperationScreenState extends ConsumerState<OperationScreen> {
  final _amountCtrl = TextEditingController();
  final _destWalletCtrl = TextEditingController();
  String _sourceOperator = _operators.first;
  String _destOperator = _operators[1];

  bool get _needsDestWallet => widget.type != OperationType.conversion;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _destWalletCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(' ', ''));
    if (amount == null || amount <= 0) {
      _snack('Montant invalide.');
      return;
    }
    if (widget.type == OperationType.conversion &&
        _sourceOperator == _destOperator) {
      _snack('Choisissez deux réseaux différents.');
      return;
    }
    if (_needsDestWallet && _destWalletCtrl.text.trim().isEmpty) {
      _snack('Numéro destinataire requis.');
      return;
    }

    // Garde PIN app (obligatoire pour toute opération).
    final pinToken = await PinPromptSheet.show(
      context,
      actionLabel: widget.title.toLowerCase(),
    );
    if (pinToken == null) return; // annulé

    await ref.read(operationControllerProvider.notifier).start(
          type: widget.type,
          sourceOperator: _sourceOperator,
          destOperator: _destOperator,
          destWallet: _needsDestWallet ? _destWalletCtrl.text.trim() : '',
          deliveryAmount: amount,
          pinToken: pinToken,
        );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(msg),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(operationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: state.when(
          data: (op) =>
              op == null ? _form() : _StatusView(op: op, onRetry: _reset),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            message: mapDioErrorToFailure(e).message,
            onRetry: _reset,
          ),
        ),
      ),
    );
  }

  void _reset() {
    ref.invalidate(operationControllerProvider);
    setState(() {});
  }

  Widget _form() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // Icône d'en-tête de l'opération
        Center(
          child: Container(
            height: 80,
            width: 80,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.08),
            ),
            child: Icon(
              widget.type == OperationType.conversion
                  ? Icons.swap_horiz_rounded
                  : widget.type == OperationType.transfer
                      ? Icons.arrow_outward_rounded
                      : Icons.phone_android_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
        ),

        // Carte principale du formulaire
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Montant à livrer (FCFA)',
                style: AppTextStyles.microLabel.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  suffixText: 'FCFA',
                  suffixStyle: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                  hintText: 'Ex. 10000',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Source Operator Dropdown
              _operatorDropdown(
                label: 'SIM source (débitée par PIN)',
                value: _sourceOperator,
                onChanged: (v) => setState(() => _sourceOperator = v),
              ),
              const SizedBox(height: AppSpacing.md),

              // Destination Operator Dropdown
              _operatorDropdown(
                label: _needsDestWallet
                    ? 'Réseau destinataire'
                    : 'SIM destination',
                value: _destOperator,
                onChanged: (v) => setState(() => _destOperator = v),
              ),

              if (_needsDestWallet) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Numéro destinataire',
                  style: AppTextStyles.microLabel.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _destWalletCtrl,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.phone_android_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    hintText: 'Ex. 70000000',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Valider la ${widget.title.toLowerCase()}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Un frais SIC s\'ajoute au montant livré ; il vous sera indiqué. '
          'Vous validerez le débit par PIN sur votre SIM source.',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _operatorDropdown({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.microLabel.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.8,
              ),
            ),
          ),
          items: [
            for (final op in _operators)
              DropdownMenuItem(
                value: op,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OperatorLogo(operatorCode: op, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      op == 'ORANGE'
                          ? 'Orange Money'
                          : op == 'MOOV'
                              ? 'Moov Money'
                              : op == 'TELECEL'
                                  ? 'Telecel Cash'
                                  : 'MTN Mobile Money',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ],
    );
  }
}

/// Vue pilotée par le statut de l'opération (machine à états).
class _StatusView extends StatelessWidget {
  const _StatusView({required this.op, required this.onRetry});

  final FloatOperation op;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, color, title, subtitle) = _visuals(op.status);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.lg),
        Center(child: Icon(icon, size: 72, color: color)),
        const SizedBox(height: AppSpacing.md),
        Text(title,
            style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xl),
        _FeeBreakdown(op: op),
        if (op.isTerminal) ...[
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Nouvelle opération'),
          ),
        ],
      ],
    );
  }

  (IconData, Color, String, String) _visuals(OperationStatus s) {
    switch (s) {
      case OperationStatus.created:
      case OperationStatus.pendingDebit:
        return (
          Icons.phonelink_lock_rounded,
          AppColors.primary,
          'Validez le PIN sur votre SIM',
          'Saisissez votre code USSD pour autoriser le débit.'
        );
      case OperationStatus.debitSuccess:
      case OperationStatus.pendingDelivery:
        return (
          Icons.sync_rounded,
          AppColors.primary,
          'Débit confirmé — livraison en cours',
          'Envoi vers la destination…'
        );
      case OperationStatus.completed:
        return (
          Icons.check_circle_rounded,
          AppColors.success,
          'Opération réussie',
          'Le montant a été livré.'
        );
      case OperationStatus.debitFailed:
        return (
          Icons.cancel_rounded,
          AppColors.danger,
          'Opération annulée',
          'Le débit n\'a pas été confirmé. Aucun montant prélevé.'
        );
      case OperationStatus.deliveryFailed:
      case OperationStatus.pendingRefund:
        return (
          Icons.autorenew_rounded,
          AppColors.primary,
          'Remboursement en cours',
          'La livraison a échoué. Remboursement automatique vers votre SIM.'
        );
      case OperationStatus.refunded:
        return (
          Icons.assignment_return_rounded,
          AppColors.success,
          'Montant remboursé',
          'Réessayez dans quelques minutes.'
        );
      case OperationStatus.refundFailed:
        return (
          Icons.error_rounded,
          AppColors.danger,
          'Contactez le support',
          'Réf. ${op.id}. Un litige a été ouvert.'
        );
      case OperationStatus.unknown:
        return (
          Icons.hourglass_empty_rounded,
          AppColors.textSecondary,
          'En cours…',
          'Suivi de l\'opération.'
        );
    }
  }
}

class _FeeBreakdown extends StatelessWidget {
  const _FeeBreakdown({required this.op});

  final FloatOperation op;

  @override
  Widget build(BuildContext context) {
    String f(double v) => '${v.toStringAsFixed(0)} FCFA';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _row('Reçu par la destination', f(op.deliveryAmount)),
          const SizedBox(height: 6),
          _row('Frais SIC', f(op.sicFee)),
          const Divider(height: 20),
          _row('Débité de votre SIM', f(op.collectAmount), strong: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool strong = false}) {
    final style = strong
        ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)
        : AppTextStyles.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style.copyWith(color: AppColors.textSecondary)),
        Text(value, style: style),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.danger),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
