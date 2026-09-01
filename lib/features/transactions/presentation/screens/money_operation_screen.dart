import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/operators.dart';
import '../../../../core/ussd/ussd_codes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/operator_selector.dart';
import '../../../../core/widgets/qr_scanner_dialog.dart';
import '../../../../core/widgets/sic_button.dart';
import '../../../../core/widgets/operator_logo.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/domain/entities/balance_summary.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/widgets/add_sim_sheet.dart';
import '../../domain/entities/operation_result.dart';
import '../providers/transaction_providers.dart';
import '../widgets/operation_success_sheet.dart';
import '../widgets/pin_prompt_sheet.dart';

import 'package:go_router/go_router.dart';

/// Type d'operation sur un numero (montant + operateur + numero du destinataire).
enum MoneyOperationKind { deposit, withdraw, transfer }

/// Formulaire de depot, retrait ou envoi P2P (montant + operateur + numero cible).
class MoneyOperationScreen extends ConsumerStatefulWidget {
  const MoneyOperationScreen({super.key, required this.kind});

  final MoneyOperationKind kind;

  String get _title => switch (kind) {
        MoneyOperationKind.deposit => 'Dépôt d\'argent',
        MoneyOperationKind.withdraw => 'Retrait d\'argent',
        MoneyOperationKind.transfer => 'Envoi / Transfert',
      };

  String get _successTitle => switch (kind) {
        MoneyOperationKind.deposit => 'Dépôt initié',
        MoneyOperationKind.withdraw => 'Retrait initié',
        MoneyOperationKind.transfer => 'Transfert initié',
      };

  String get _ctaLabel => switch (kind) {
        MoneyOperationKind.deposit => 'Confirmer le dépôt',
        MoneyOperationKind.withdraw => 'Confirmer le retrait',
        MoneyOperationKind.transfer => 'Confirmer l\'envoi',
      };

  String get _pinActionLabel => switch (kind) {
        MoneyOperationKind.deposit => 'le dépôt',
        MoneyOperationKind.withdraw => 'le retrait',
        MoneyOperationKind.transfer => 'l\'envoi',
      };

  (IconData, List<Color>) get _visualIcon => switch (kind) {
        MoneyOperationKind.deposit => (
            Icons.south_west_rounded,
            [const Color(0xFF059669), const Color(0xFF10B981)],
          ),
        MoneyOperationKind.withdraw => (
            Icons.north_east_rounded,
            [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)],
          ),
        MoneyOperationKind.transfer => (
            Icons.swap_horiz_rounded,
            [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)],
          ),
      };

  @override
  ConsumerState<MoneyOperationScreen> createState() =>
      _MoneyOperationScreenState();
}

class _MoneyOperationScreenState extends ConsumerState<MoneyOperationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  late String _operatorCode;
  bool _isSubmitting = false;
  String? _selectedSimKey;

  String _getPhoneLabel(bool isClient) => switch (widget.kind) {
        MoneyOperationKind.withdraw =>
          isClient ? 'Numéro de l\'agent' : 'Numéro du client',
        MoneyOperationKind.deposit =>
          isClient ? 'Numéro de l\'agent' : 'Numéro du client',
        MoneyOperationKind.transfer => 'Numéro du destinataire',
      };

  @override
  void initState() {
    super.initState();
    const operators = kAvailableOperators;
    _operatorCode = operators.keys.isNotEmpty ? operators.keys.first : 'OM';
    // Retrait : le code USSD cash-out affiché dépend du montant saisi -> rebuild.
    _amountController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const operators = kAvailableOperators;
    final (icon, colors) = widget._visualIcon;
    final user = ref.watch(authControllerProvider).valueOrNull;
    final isClient = user?.isClient ?? true;
    final summary = !isClient ? ref.watch(dashboardNotifierProvider).valueOrNull : null;
    final sims = summary?.balances ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget._title,
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E293B), size: 20),
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
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Icône centrale moderne de l'opération
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.first.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 18),

                  // Carte principale du formulaire centrée
                  Container(
                    padding: const EdgeInsets.all(22),
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Montant de l\'opération',
                              style: AppTextStyles.microLabel.copyWith(
                                color: const Color(0xFF0F172A),
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Ex: 5000',
                            suffixText: 'FCFA',
                            suffixStyle: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                            ),
                            prefixIcon: Icon(
                              Icons.payments_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                          ),
                          validator: Validators.validateAmount,
                        ),
                        const SizedBox(height: 22),

                        if (!isClient) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                  Icons.sim_card_rounded,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'SIM Agent source (Puce marchande)',
                                style: AppTextStyles.microLabel.copyWith(
                                  color: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildAgentSimSelector(context, sims),
                          if (widget.kind == MoneyOperationKind.withdraw)
                            _buildWithdrawCashoutHint(sims),
                          const SizedBox(height: 22),
                        ] else ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                  Icons.cell_tower_rounded,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Réseau / Opérateur',
                                style: AppTextStyles.microLabel.copyWith(
                                  color: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          OperatorSelector(
                            operators: operators,
                            selectedOperatorCode: _operatorCode,
                            onSelected: (code) => setState(() => _operatorCode = code),
                          ),
                          const SizedBox(height: 22),
                        ],

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.phone_iphone_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _getPhoneLabel(isClient),
                              style: AppTextStyles.microLabel.copyWith(
                                color: const Color(0xFF0F172A),
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                            LengthLimitingTextInputFormatter(15),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Ex: 70 00 00 00',
                            prefixIcon: const Icon(
                              Icons.contact_phone_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            suffixIcon: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              tooltip: 'Scanner un QR Code',
                              onPressed: _scanQrCode,
                            ),
                          ),
                          validator: (v) =>
                              Validators.validateOperatorPhone(v, _operatorCode),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SicButton(
                    label: widget._ctaLabel,
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

  Future<void> _scanQrCode() async {
    final result = await QrScannerDialog.show(context);
    if (result != null && mounted) {
      if (result.phoneNumber != null) {
        _phoneController.text = result.phoneNumber!;
      }
      if (result.operatorCode != null && kAvailableOperators.containsKey(result.operatorCode)) {
        setState(() => _operatorCode = result.operatorCode!);
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              result.hasPhone
                  ? 'Numéro et opérateur scannés avec succès !'
                  : 'QR Code scanné.',
            ),
          ),
        );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Regle mobile money : aucune operation sans le code PIN.
    final pinToken = await PinPromptSheet.show(
      context,
      actionLabel: widget._pinActionLabel,
    );
    if (pinToken == null || !mounted) return; // agent a annule.

    final amount = double.parse(_amountController.text.trim());
    final phone = _phoneController.text.trim();
    final repo = ref.read(transactionRepositoryProvider);

    setState(() => _isSubmitting = true);
    final result = switch (widget.kind) {
      MoneyOperationKind.deposit => await repo.deposit(
          amount: amount,
          operatorCode: _operatorCode,
          phoneNumber: phone,
          pinToken: pinToken,
        ),
      MoneyOperationKind.withdraw => await repo.withdraw(
          amount: amount,
          operatorCode: _operatorCode,
          phoneNumber: phone,
          pinToken: pinToken,
        ),
      MoneyOperationKind.transfer => await repo.transfer(
          amount: amount,
          operatorCode: _operatorCode,
          phoneNumber: phone,
          pinToken: pinToken,
        ),
    };

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
    // Les soldes ont change cote serveur : on rafraichit dashboard + historique.
    await ref.read(dashboardNotifierProvider.notifier).refresh();
    await ref.read(transactionsNotifierProvider.notifier).refresh();

    if (!mounted) return;
    await OperationSuccessSheet.show(
      context,
      title: widget._successTitle,
      result: operation,
    );

    if (mounted) Navigator.of(context).pop();
  }

  Widget _buildAgentSimSelector(BuildContext context, List<BalanceSummary> sims) {
    if (sims.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDBEAFE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Aucune puce marchande enregistrée.',
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => AddSimSheet.show(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Ajouter SIM', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    final uniqueSims = <String, BalanceSummary>{};
    for (final sim in sims) {
      final key = sim.id ?? '${sim.operatorCode}_${sim.phoneNumber}';
      uniqueSims.putIfAbsent(key, () => sim);
    }
    final simList = uniqueSims.values.toList();
    final currentKey = _selectedSimKey ??
        (simList.isNotEmpty
            ? (simList.first.id ?? '${simList.first.operatorCode}_${simList.first.phoneNumber}')
            : null);

    return DropdownButtonFormField<String>(
      value: uniqueSims.containsKey(currentKey)
          ? currentKey
          : (simList.first.id ?? '${simList.first.operatorCode}_${simList.first.phoneNumber}'),
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.sim_card_rounded, color: AppColors.primary, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
      ),
      items: [
        for (final sim in simList)
          DropdownMenuItem(
            value: sim.id ?? '${sim.operatorCode}_${sim.phoneNumber}',
            child: Row(
              children: [
                OperatorLogo(operatorCode: sim.operatorCode, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Le CODE MARCHAND est le numero que le client compose
                      // (ex. *144*3*<code>*montant#). On l'affiche en principal.
                      Text(
                        sim.merchantCode.isNotEmpty
                            ? '${sim.operatorName} · Code ${sim.merchantCode}'
                            : '${sim.operatorName} · ${sim.phoneNumber}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        sim.merchantCode.isNotEmpty
                            ? 'SIM ${sim.phoneNumber}'
                            : 'Code marchand non renseigné',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: AppTextStyles.caption.copyWith(
                          color: sim.merchantCode.isNotEmpty
                              ? AppColors.textSecondary
                              : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          _selectedSimKey = v;
          final matched = uniqueSims[v];
          if (matched != null) {
            _operatorCode = matched.operatorCode;
          }
        });
      },
    );
  }

  /// Retrait = cash-out USSD : affiche le code EXACT que le CLIENT compose sur
  /// SON téléphone (*144*3*<code marchand>*<montant>#), avec bouton copier.
  Widget _buildWithdrawCashoutHint(List<BalanceSummary> sims) {
    if (sims.isEmpty) return const SizedBox.shrink();
    final key = _selectedSimKey;
    final sim = sims.firstWhere(
      (s) => (s.id ?? '${s.operatorCode}_${s.phoneNumber}') == key,
      orElse: () => sims.first,
    );

    if (sim.merchantCode.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _hintBox(
          color: AppColors.danger,
          icon: Icons.warning_amber_rounded,
          text: "Cette SIM n'a pas de code marchand. Ajoutez-le pour générer "
              "le code de retrait que le client compose.",
        ),
      );
    }

    final amount = int.tryParse(_amountController.text.trim());
    final code = UssdShortcuts.build(
      sim.operatorCode,
      UssdOperation.cashout,
      merchant: sim.merchantCode,
      amount: amount,
    );

    if (code == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _hintBox(
          color: AppColors.primary,
          icon: Icons.info_outline_rounded,
          text: "Le client envoie au code marchand ${sim.merchantCode} "
              "(code USSD ${sim.operatorName} à confirmer).",
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le client compose ce code sur SON téléphone, puis valide avec son PIN :',
              style: AppTextStyles.caption
                  .copyWith(color: const Color(0xFF065F46)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    code,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF065F46),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded,
                      size: 20, color: Color(0xFF059669)),
                  tooltip: 'Copier',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Code copié.'),
                      ));
                  },
                ),
              ],
            ),
            if (amount == null)
              Text(
                'Saisissez le montant pour compléter le code.',
                style: AppTextStyles.caption
                    .copyWith(color: const Color(0xFF047857)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _hintBox({
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: AppTextStyles.caption.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
