import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_failure.dart';
import '../../../../core/utils/fcfa_formatter.dart';
import '../../../../core/widgets/operator_logo.dart';
import '../../../../core/widgets/operator_selector.dart';
import '../../../../core/widgets/qr_scanner_dialog.dart';
import '../../../../core/widgets/sic_button.dart';
import '../../../../core/network/operator_mapping.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/domain/entities/balance_summary.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/widgets/add_sim_sheet.dart';
import '../../../transactions/presentation/widgets/pin_prompt_sheet.dart';
import '../../domain/entities/float_operation.dart';
import '../providers/operation_provider.dart';

import 'package:go_router/go_router.dart';

const _operators = ['ORANGE', 'MOOV', 'TELECEL', 'MTN', 'WAVE', 'SANK', 'CORIS'];

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

  /// SIM float source choisie (cle = id de puce, sinon numero). Cote agent, la
  /// source est une VRAIE SIM enregistree (pas un operateur generique).
  String? _sourceSimId;

  String get _buttonLabel {
    final title = widget.title.toLowerCase();
    if (title.contains('envoy') || title.contains('transfer')) {
      return 'Valider l\'envoi';
    } else if (title.contains('dépôt') || title.contains('depot')) {
      return 'Valider le dépôt';
    } else if (title.contains('retrait')) {
      return 'Valider le retrait';
    } else if (title.contains('conversion')) {
      return 'Valider la conversion';
    }
    return 'Valider l\'opération';
  }

  bool get _needsDestWallet => widget.type != OperationType.conversion;

  /// Cle stable d'une SIM pour le dropdown (id backend, sinon le numero/code).
  String _simKey(BalanceSummary sim) =>
      sim.id ?? '${sim.operatorCode}_${sim.phoneNumber}';

  /// Les SIM float reelles de l'agent (vides pour un client).
  List<BalanceSummary> _agentSims() =>
      ref.read(dashboardNotifierProvider).valueOrNull?.balances ??
      const <BalanceSummary>[];

  /// La SIM source effective : celle choisie, sinon la premiere disponible.
  BalanceSummary? _effectiveSourceSim(List<BalanceSummary> sims) {
    if (sims.isEmpty) return null;
    return sims.firstWhere(
      (s) => _simKey(s) == _sourceSimId,
      orElse: () => sims.first,
    );
  }

  String _getPhoneLabel(bool isClient) {
    final title = widget.title.toLowerCase();
    if (title.contains('retrait')) {
      return isClient ? 'Numéro de l\'agent' : 'Numéro du client';
    } else if (title.contains('dépôt') || title.contains('depot')) {
      return isClient ? 'Numéro de l\'agent' : 'Numéro du client';
    }
    return 'Numéro destinataire';
  }

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_onAmountChanged);
    _amountCtrl.dispose();
    _destWalletCtrl.dispose();
    super.dispose();
  }

  double? _getAvailableBalance() {
    final dashboardState = ref.read(dashboardNotifierProvider);
    final user = ref.read(authControllerProvider).valueOrNull;
    final isClient = user?.isClient ?? false;
    final summary = dashboardState.valueOrNull;
    
    if (summary != null) {
      if (isClient) {
        return summary.totalBalance;
      } else {
        // Agent : solde de la SIM float source effectivement selectionnee.
        final sim = _effectiveSourceSim(summary.balances);
        if (sim != null) return sim.balance;
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(' ', ''));
    if (amount == null || amount <= 0) {
      _snack('Montant invalide.');
      return;
    }

    // Cote agent, la source est une VRAIE SIM float : on en derive l'operateur
    // backend. Cote client (pas de SIM), on garde l'operateur generique choisi.
    final user = ref.read(authControllerProvider).valueOrNull;
    final isClient = user?.isClient ?? false;
    final sims = _agentSims();
    final sourceSim = isClient ? null : _effectiveSourceSim(sims);
    if (!isClient && sourceSim == null) {
      _snack('Ajoutez d\'abord une SIM float pour effectuer une opération.');
      return;
    }
    final sourceOperator = sourceSim != null
        ? OperatorMapping.toBackend(sourceSim.operatorCode)
        : _sourceOperator;

    final balance = _getAvailableBalance();
    if (balance != null && amount > balance) {
      _snack('Solde insuffisant pour cette opération.');
      return;
    }

    if (widget.type == OperationType.conversion &&
        sourceOperator == _destOperator) {
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
          sourceOperator: sourceOperator,
          destOperator: _destOperator,
          destWallet: _needsDestWallet ? _destWalletCtrl.text.trim() : '',
          deliveryAmount: amount,
          pinToken: pinToken,
        );
  }

  Future<void> _scanQrCodeForOperation() async {
    final result = await QrScannerDialog.show(context);
    if (result != null && mounted) {
      if (result.phoneNumber != null) {
        _destWalletCtrl.text = result.phoneNumber!;
      }
      if (result.operatorCode != null) {
        final matchedOp = _operators.firstWhere(
          (op) => op.toLowerCase() == result.operatorCode!.toLowerCase(),
          orElse: () => _destOperator,
        );
        setState(() => _destOperator = matchedOp);
      }
      _snack(result.hasPhone
          ? 'Numéro et réseau destinataire scannés !'
          : 'QR Code scanné.');
    }
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.title,
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

  (IconData, List<Color>) get _operationVisuals => switch (widget.type) {
        OperationType.conversion => (
            Icons.currency_exchange_rounded,
            [const Color(0xFF7C3AED), const Color(0xFF9333EA)],
          ),
        OperationType.transfer => (
            Icons.swap_horiz_rounded,
            [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)],
          ),
        OperationType.airtime => (
            Icons.signal_cellular_alt_rounded,
            [const Color(0xFF059669), const Color(0xFF10B981)],
          ),
      };

  Widget _form() {
    final (icon, colors) = _operationVisuals;
    final user = ref.watch(authControllerProvider).valueOrNull;
    final isClient = user?.isClient ?? false;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône d'en-tête de l'opération (moderne & colorée)
            Container(
              height: 68,
              width: 68,
              margin: const EdgeInsets.only(bottom: 16),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFF2563EB), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Montant à livrer (FCFA)',
                    style: AppTextStyles.microLabel.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.payments_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                  suffixText: 'FCFA',
                  suffixStyle: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                  hintText: 'Ex. 10000',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.8,
                    ),
                  ),
                ),
              ),
              _buildBalanceHelper(),
              const SizedBox(height: 14),

              // Source : cote agent, une VRAIE SIM float ; cote client, le
              // reseau generique de sa propre ligne.
              _buildSourceSelector(),
              const SizedBox(height: 14),

              // Destination Operator Dropdown
              _operatorDropdown(
                label: _needsDestWallet
                    ? 'Réseau destinataire'
                    : 'SIM destination',
                value: _destOperator,
                onChanged: (v) => setState(() => _destOperator = v),
              ),

              if (_needsDestWallet) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.phone_iphone_rounded,
                          color: Color(0xFF2563EB), size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getPhoneLabel(isClient),
                      style: AppTextStyles.microLabel.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _destWalletCtrl,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.contact_phone_rounded,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
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
                      onPressed: _scanQrCodeForOperation,
                    ),
                    hintText: 'Ex. 70000000',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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

          const SizedBox(height: 14),
          SicButton(
            label: _buttonLabel,
            onPressed: _submit,
          ),
          const SizedBox(height: 10),
          Text(
            'Un frais SIC s\'ajoute au montant livré ; il vous sera indiqué. '
            'Vous validerez le débit par PIN sur votre SIM source.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.3,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );
}

  /// Selecteur de source : cote agent, la liste de ses VRAIES SIM float
  /// (numero + operateur + code marchand) ; cote client, l'operateur generique.
  /// Selecteur de source : cote agent, la liste de ses VRAIES SIM float
  /// (numero + operateur + code marchand) ; cote client, l'operateur generique.
  Widget _buildSourceSelector() {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final isClient = user?.isClient ?? false;
    final dashboardState = ref.watch(dashboardNotifierProvider);

    if (!isClient) {
      return dashboardState.when(
        data: (summary) {
          final sims = summary.balances;
          return sims.isEmpty ? _noSimNotice() : _sourceSimSelector(sims);
        },
        loading: () => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: const [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                'Chargement des SIM float...',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        error: (_, __) => _noSimNotice(),
      );
    }
    // Client : pas de SIM float, la source est sa propre ligne (reseau).
    return _operatorDropdown(
      label: 'SIM source (débitée par PIN)',
      value: _sourceOperator,
      onChanged: (v) => setState(() => _sourceOperator = v),
    );
  }

  /// Aucune SIM float enregistree : on invite l'agent a en ajouter une.
  Widget _noSimNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sim_card_alert_rounded,
                  color: Color(0xFFEA580C), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aucune SIM float enregistrée',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF9A3412),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ajoutez une SIM (avec son code marchand) depuis l\'accueil pour effectuer une opération.',
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF9A3412),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              context.go('/dashboard');
              Future.microtask(() => AddSimSheet.show(context));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC2410C),
              side: const BorderSide(color: Color(0xFFF97316)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.add_card_rounded, size: 16),
            label: const Text(
              'Ajouter une SIM float',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Dropdown des SIM float reelles de l'agent.
  Widget _sourceSimSelector(List<BalanceSummary> sims) {
    final uniqueSims = <String, BalanceSummary>{};
    for (final sim in sims) {
      uniqueSims.putIfAbsent(_simKey(sim), () => sim);
    }
    final simList = uniqueSims.values.toList();
    final selected = _effectiveSourceSim(simList);
    final selectedKey = selected == null ? null : _simKey(selected);
    final validKey = uniqueSims.containsKey(selectedKey)
        ? selectedKey
        : (simList.isNotEmpty ? _simKey(simList.first) : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SIM source (débitée par PIN)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.microLabel.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          value: validKey,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.sim_card_rounded,
                color: AppColors.primary, size: 20),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.8),
            ),
          ),
          items: [
            for (final sim in simList)
              DropdownMenuItem(
                value: _simKey(sim),
                child: Row(
                  children: [
                    OperatorLogo(operatorCode: sim.operatorCode, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _simLabel(sim),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _sourceSimId = v);
          },
        ),
      ],
    );
  }

  /// Libelle d'une SIM : « Numéro · Opérateur [· Code XXXX] ».
  String _simLabel(BalanceSummary sim) {
    final buf = StringBuffer('${sim.phoneNumber} · ${sim.operatorName}');
    if (sim.merchantCode.isNotEmpty) buf.write(' · Code ${sim.merchantCode}');
    return buf.toString();
  }

  Widget _operatorDropdown({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    final opsMap = <String, String>{
      for (final op in _operators)
        op: OperatorMapping.fromBackend(op).name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cell_tower_rounded,
                color: Color(0xFF3B82F6), size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.microLabel.copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OperatorSelector(
          operators: opsMap,
          selectedOperatorCode: value,
          onSelected: onChanged,
        ),
      ],
    );
  }

  Widget _buildBalanceHelper() {
    final balance = _getAvailableBalance();
    if (balance == null) return const SizedBox.shrink();

    final enteredAmount = double.tryParse(_amountCtrl.text.trim().replaceAll(' ', '')) ?? 0.0;
    final isBalanceInsufficient = enteredAmount > balance;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Solde disponible : ${FcfaFormatter.format(balance)}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: isBalanceInsufficient ? AppColors.danger : AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              if (balance < 10000) ...[
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Solde bas',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (isBalanceInsufficient) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ Solde insuffisant (manque ${FcfaFormatter.format(enteredAmount - balance)})',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
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
        Expanded(
          child: Text(
            label,
            style: style.copyWith(color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
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
