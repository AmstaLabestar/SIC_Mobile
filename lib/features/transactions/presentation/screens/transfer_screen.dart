import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/fcfa_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/operator_logo.dart';
import '../../../../core/widgets/sic_button.dart';
import '../../../dashboard/domain/entities/balance_summary.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/widgets/add_sim_sheet.dart';
import '../../domain/entities/operation_result.dart';
import '../providers/transaction_providers.dart';
import '../widgets/operation_success_sheet.dart';
import '../widgets/pin_prompt_sheet.dart';

/// Conversion / rééquilibrage de float entre deux puces de l'agent (swap interne).
class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _sourceId;
  String? _targetId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  String _simKey(BalanceSummary sim) =>
      sim.id ?? '${sim.operatorCode}_${sim.phoneNumber}';

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(dashboardNotifierProvider).valueOrNull;
    final puces = (summary?.balances ?? const <BalanceSummary>[]);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Conversion (Rééquilibrage)',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            fontSize: 19,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: puces.length < 2
                ? _NotEnoughPucesNotice()
                : Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icône d'en-tête conversion (Violet / Violet vif)
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.currency_exchange_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Carte principale du formulaire
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E3A8A).withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Puce Source
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.sim_card_rounded,
                                      color: Color(0xFF7C3AED),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Puce source (à débiter)',
                                    style: AppTextStyles.microLabel.copyWith(
                                      color: const Color(0xFF0F172A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _puceDropdown(
                                value: _sourceId ?? _simKey(puces.first),
                                puces: puces,
                                onChanged: (v) => setState(() {
                                  _sourceId = v;
                                  if (_targetId == v) _targetId = null;
                                }),
                              ),
                              _buildBalanceHelper(puces),
                              const SizedBox(height: 16),

                              // 2. Puce Destination
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.sim_card_download_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Puce destination (à créditer)',
                                    style: AppTextStyles.microLabel.copyWith(
                                      color: const Color(0xFF0F172A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _puceDropdown(
                                value: _targetId,
                                hintText: 'Sélectionner la puce destination',
                                puces: puces
                                    .where((p) =>
                                        _simKey(p) !=
                                        (_sourceId ?? _simKey(puces.first)))
                                    .toList(),
                                onChanged: (v) => setState(() => _targetId = v),
                              ),
                              const SizedBox(height: 16),

                              // 3. Montant
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.payments_rounded,
                                      color: Color(0xFF059669),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Montant de la conversion (FCFA)',
                                    style: AppTextStyles.microLabel.copyWith(
                                      color: const Color(0xFF0F172A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Ex: 10000',
                                  suffixText: 'FCFA',
                                  suffixStyle: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64748B),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Color(0xFF7C3AED),
                                    size: 20,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                                validator: _validateAmount,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        SicButton(
                          label: 'Confirmer la conversion',
                          isLoading: _isSubmitting,
                          onPressed: _isSubmitting ? null : _submit,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _puceDropdown({
    required String? value,
    required List<BalanceSummary> puces,
    required ValueChanged<String?> onChanged,
    String hintText = 'Choisir une puce',
  }) {
    final uniquePuces = <String, BalanceSummary>{};
    for (final p in puces) {
      uniquePuces.putIfAbsent(_simKey(p), () => p);
    }
    final list = uniquePuces.values.toList();
    final validValue = uniquePuces.containsKey(value) ? value : null;

    return DropdownButtonFormField<String>(
      value: validValue,
      isExpanded: true,
      hint: Text(
        hintText,
        style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
      ),
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.sim_card_rounded,
          color: Color(0xFF7C3AED),
          size: 20,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.8),
        ),
      ),
      items: [
        for (final p in list)
          DropdownMenuItem(
            value: _simKey(p),
            child: Row(
              children: [
                OperatorLogo(operatorCode: p.operatorCode, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${p.operatorName} · ${p.phoneNumber}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
      validator: (v) => v == null ? 'Sélectionnez une puce.' : null,
      onChanged: onChanged,
    );
  }

  Widget _buildBalanceHelper(List<BalanceSummary> puces) {
    final effectiveSourceId = _sourceId ?? (puces.isNotEmpty ? _simKey(puces.first) : null);
    if (effectiveSourceId == null) return const SizedBox.shrink();

    final matches = puces.where((p) => _simKey(p) == effectiveSourceId).toList();
    if (matches.isEmpty) return const SizedBox.shrink();

    final sourcePuce = matches.first;
    final balance = sourcePuce.balance;
    final enteredAmount =
        double.tryParse(_amountController.text.trim().replaceAll(' ', '')) ?? 0.0;
    final isInsufficient = enteredAmount > balance;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solde disponible : ${FcfaFormatter.format(balance)}',
            style: TextStyle(
              color: isInsufficient ? AppColors.danger : AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          if (isInsufficient) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '⚠️ Solde insuffisant (manque ${FcfaFormatter.format(enteredAmount - balance)})',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _validateAmount(String? value) {
    final base = Validators.validateAmount(value);
    if (base != null) return base;
    final amount = double.tryParse(value!.trim()) ?? 0;
    final puces = ref.read(dashboardNotifierProvider).valueOrNull?.balances ?? [];
    final effectiveSourceId = _sourceId ?? (puces.isNotEmpty ? _simKey(puces.first) : null);
    final matches = puces.where((p) => _simKey(p) == effectiveSourceId).toList();
    if (matches.isNotEmpty && amount > matches.first.balance) {
      return 'Solde insuffisant sur la puce source.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final puces = ref.read(dashboardNotifierProvider).valueOrNull?.balances ?? [];
    final sourcePuceId = _sourceId ?? (puces.isNotEmpty ? _simKey(puces.first) : null);
    if (sourcePuceId == null || _targetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Veuillez sélectionner les puces source et destination.'),
        ),
      );
      return;
    }

    final pinToken = await PinPromptSheet.show(
      context,
      actionLabel: 'la conversion',
    );
    if (pinToken == null || !mounted) return;

    final amount = double.parse(_amountController.text.trim());
    final repo = ref.read(transactionRepositoryProvider);

    setState(() => _isSubmitting = true);
    final result = await repo.convert(
      amount: amount,
      sourcePuceId: sourcePuceId,
      targetPuceId: _targetId!,
      pinToken: pinToken,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    await result.fold(
      (failure) async {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(failure.message),
            ),
          );
      },
      (operation) => _onSuccess(operation),
    );
  }

  Future<void> _onSuccess(OperationResult operation) async {
    await ref.read(dashboardNotifierProvider.notifier).refresh();
    await ref.read(transactionsNotifierProvider.notifier).refresh();

    if (!mounted) return;
    await OperationSuccessSheet.show(
      context,
      title: 'Conversion effectuée',
      result: operation,
    );

    if (mounted) Navigator.of(context).pop();
  }
}

class _NotEnoughPucesNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              size: 40,
              color: Color(0xFFEA580C),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Au moins 2 puces SIM requises',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'La conversion permet de rééquilibrer le float entre deux de vos puces marchandes. Veuillez en enregistrer au moins deux.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              context.go('/dashboard');
              Future.microtask(() => AddSimSheet.show(context));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.add_card_rounded, size: 18),
            label: const Text(
              'Ajouter une puce marchande',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
