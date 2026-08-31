import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/sic_button.dart';
import '../../domain/entities/bill_transaction.dart';
import '../providers/bills_provider.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key, this.initialService});

  final String? initialService;

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  // Service sélectionné : CASHPOWER vs ONEA
  late String _selectedService;

  // Portefeuille sélectionné
  String _selectedWallet = 'WAVE';

  @override
  void initState() {
    super.initState();
    _selectedService = widget.initialService ?? 'CASHPOWER';
  }

  // Contrôleurs de texte
  final _meterController = TextEditingController();
  final _amountController = TextEditingController();

  // État inquiry ONEA
  bool _isCheckingInquiry = false;
  BillInquiryResult? _inquiryResult;
  String? _inquiryError;

  // Configuration des 6 portefeuilles
  final List<Map<String, dynamic>> _wallets = [
    {
      'code': 'WAVE',
      'name': 'Wave',
      'color': const Color(0xFF00ADEE),
      'icon': Icons.waves_rounded,
    },
    {
      'code': 'ORANGE',
      'name': 'Orange Money',
      'color': const Color(0xFFFF6600),
      'icon': Icons.phone_android_rounded,
    },
    {
      'code': 'MOOV',
      'name': 'Moov Money',
      'color': const Color(0xFF0050A0),
      'icon': Icons.account_balance_wallet_rounded,
    },
    {
      'code': 'TELECEL',
      'name': 'Telecel Money',
      'color': const Color(0xFFE30613),
      'icon': Icons.send_to_mobile_rounded,
    },
    {
      'code': 'CORIS',
      'name': 'Coris Money',
      'color': const Color(0xFFA8191E),
      'icon': Icons.account_balance_rounded,
    },
    {
      'code': 'SANK',
      'name': 'Sank Money',
      'color': const Color(0xFF009639),
      'icon': Icons.payments_rounded,
    },
  ];

  @override
  void dispose() {
    _meterController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onServiceChanged(String service) {
    setState(() {
      _selectedService = service;
      _inquiryResult = null;
      _inquiryError = null;
      _amountController.clear();
    });
  }

  Future<void> _runOneaInquiry() async {
    final refStr = _meterController.text.trim();
    if (refStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir votre référence ou N° de compteur ONEA.')),
      );
      return;
    }

    setState(() {
      _isCheckingInquiry = true;
      _inquiryError = null;
      _inquiryResult = null;
    });

    try {
      final res = await ref.read(billsControllerProvider.notifier).inquiry(
            serviceType: 'ONEA',
            meterReference: refStr,
          );
      setState(() {
        _isCheckingInquiry = false;
        if (res.success) {
          _inquiryResult = res;
          _amountController.text = res.amountDue.toStringAsFixed(0);
        } else {
          _inquiryError = res.errorMessage ?? 'Introuvable auprès de l\'ONEA.';
        }
      });
    } catch (e) {
      setState(() {
        _isCheckingInquiry = false;
        _inquiryError = 'Erreur de connexion au facturier ONEA.';
      });
    }
  }

  Future<void> _submitPayment() async {
    final meter = _meterController.text.trim();
    final amountText = _amountController.text.trim();

    if (meter.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner le numéro de compteur ou référence.')),
      );
      return;
    }

    if (_selectedService == 'ONEA' && _inquiryResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord interroger la facture ONEA.')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide.')),
      );
      return;
    }

    final idempotencyKey = 'MOBILE_BILL_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final tx = await ref.read(billsControllerProvider.notifier).initiatePayment(
            serviceType: _selectedService,
            walletCode: _selectedWallet,
            meterReference: meter,
            amount: amount,
            idempotencyKey: idempotencyKey,
          );

      if (mounted) {
        _showResultDialog(tx);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec du paiement : $e')),
        );
      }
    }
  }

  void _showResultDialog(BillTransactionEntity tx) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tx.serviceType == 'CASHPOWER' ? 'Recharge CASHPOWER' : 'Paiement ONEA',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compteur / Réf : ${tx.meterReference}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              'Montant réglé : ${tx.amount.toStringAsFixed(0)} FCFA',
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (tx.serviceType == 'CASHPOWER' && tx.tokenSts != null) ...[
              const Text(
                'TOKEN STS (20 CHIFFRES) :',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  tx.tokenSts!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ] else if (tx.receiptNumber != null) ...[
              const Text(
                'QUITTANCE / REÇU :',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  tx.receiptNumber!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (tx.tokenSts != null || tx.receiptNumber != null)
            TextButton.icon(
              onPressed: () {
                final copyText = tx.tokenSts ?? tx.receiptNumber ?? '';
                Clipboard.setData(ClipboardData(text: copyText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copié dans le presse-papier !')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(tx.tokenSts != null ? 'Copier le Token' : 'Copier le Reçu'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _meterController.clear();
                _amountController.clear();
                _inquiryResult = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Fermer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billsControllerProvider);
    final isLoading = state.isLoading || _isCheckingInquiry;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Paiement de Factures',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Onglets Sélecteurs de Service : CASHPOWER vs ONEA
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildServiceTab(
                        code: 'CASHPOWER',
                        title: 'CASHPOWER',
                        subtitle: 'SONABEL Électricité',
                        icon: Icons.electric_bolt_rounded,
                        color: const Color(0xFFEAB308),
                      ),
                    ),
                    Expanded(
                      child: _buildServiceTab(
                        code: 'ONEA',
                        title: 'ONEA',
                        subtitle: 'Facture d\'Eau',
                        icon: Icons.water_drop_rounded,
                        color: const Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Carte Principale de Formulaire
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre d'instruction
                    Text(
                      _selectedService == 'CASHPOWER'
                          ? '⚡ Recharge Électricité prépayée'
                          : '💧 Règlement Facture d\'Eau ONEA',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Champ N° Compteur ou Référence
                    TextField(
                      controller: _meterController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: _selectedService == 'CASHPOWER'
                            ? 'N° de Compteur CASHPOWER'
                            : 'Référence / N° Compteur ONEA',
                        hintText: _selectedService == 'CASHPOWER' ? 'Ex: 1428592019' : 'Ex: FAC-ONEA-789',
                        prefixIcon: Icon(
                          _selectedService == 'CASHPOWER' ? Icons.numbers_rounded : Icons.receipt_long_rounded,
                          color: AppColors.primary,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Si ONEA : Bouton "Interroger la facture" et Résultat Inquiry
                    if (_selectedService == 'ONEA') ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : _runOneaInquiry,
                          icon: _isCheckingInquiry
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search_rounded),
                          label: const Text('Rechercher la facture dûe'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      if (_inquiryError != null) ...[
                        const SizedBox(height: 8),
                        Text(_inquiryError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ],
                      if (_inquiryResult != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Abonné : ${_inquiryResult!.customerName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Montant exact à payer : ${_inquiryResult!.amountDue.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],

                    // Champ Montant FCFA (Libre pour CASHPOWER, Verrouillé pour ONEA)
                    TextField(
                      controller: _amountController,
                      readOnly: _selectedService == 'ONEA',
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Montant à payer (FCFA)',
                        hintText: 'Ex: 5000',
                        prefixIcon: const Icon(Icons.monetization_on_rounded, color: AppColors.primary),
                        filled: true,
                        fillColor: _selectedService == 'ONEA' ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),

                    // Quick Chips pour CASHPOWER
                    if (_selectedService == 'CASHPOWER') ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [2000, 5000, 10000, 20000].map((amt) {
                          return ActionChip(
                            label: Text('$amt F'),
                            backgroundColor: const Color(0xFFF1F5F9),
                            onPressed: () {
                              setState(() {
                                _amountController.text = amt.toString();
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Sélecteur des 6 Portefeuilles Mobile Money
              const Text(
                'CHOISISSEZ VOTRE PORTEFEUILLE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _wallets.length,
                itemBuilder: (ctx, idx) {
                  final wallet = _wallets[idx];
                  final isSelected = _selectedWallet == wallet['code'];
                  final Color color = wallet['color'];

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedWallet = wallet['code'];
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            wallet['icon'],
                            color: isSelected ? color : const Color(0xFF64748B),
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            wallet['name'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? color : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // 4. Bouton de Confirmation de Paiement
              SicButton(
                label: 'VALIDER ET PAYER',
                onPressed: isLoading ? null : _submitPayment,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTab({
    required String code,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedService == code;
    return GestureDetector(
      onTap: () => _onServiceChanged(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : const Color(0xFF64748B), size: 22),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
