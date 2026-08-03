import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../utils/fcfa_formatter.dart';

/// Service responsable de la création, mise en page, impression et partage
/// des reçus de transaction au format PDF pour l'application SIC.
class ReceiptPdfService {
  const ReceiptPdfService._();

  /// Génère le document PDF vectoriel pour une transaction.
  static Future<Uint8List> buildReceiptPdf({
    required String transactionId,
    required String title,
    required double amount,
    required String status,
    required DateTime createdAt,
    double? commissionSic,
    String? operatorName,
    String? phoneNumber,
    List<Map<String, dynamic>>? compensationDetails,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final formattedDate = dateFormat.format(createdAt);
    final isSuccess = status.toUpperCase() == 'SUCCESS' ||
        status.toUpperCase() == 'COMPLETED' ||
        status.toUpperCase() == 'SUCCÈS';
    final isPending = status.toUpperCase() == 'PENDING';

    final primaryColor = PdfColor.fromHex('#0066FF');
    final darkColor = PdfColor.fromHex('#1E293B');
    final lightBg = PdfColor.fromHex('#F8FAFC');
    final successColor = PdfColor.fromHex('#10B981');
    final warningColor = PdfColor.fromHex('#F59E0B');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // --- EN-TÊTE ---
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SIC',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.Text(
                          'Système Inter-Connexion',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: isSuccess
                            ? PdfColor.fromHex('#ECFDF5')
                            : (isPending
                                ? PdfColor.fromHex('#FFFBEB')
                                : PdfColor.fromHex('#FEF2F2')),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        isSuccess
                            ? 'RÉUSSITE'
                            : (isPending ? 'EN ATTENTE' : status.toUpperCase()),
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: isSuccess
                              ? successColor
                              : (isPending ? warningColor : PdfColors.red800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // --- TITRE & MONTANT ---
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      title.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      FcfaFormatter.format(amount),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: darkColor,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // --- DÉTAILS DE LA TRANSACTION ---
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey200),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  children: [
                    _buildRow('Référence ID', _shortId(transactionId)),
                    _buildRow('Date & Heure', formattedDate),
                    if (operatorName != null && operatorName.isNotEmpty)
                      _buildRow('Opérateur', operatorName),
                    if (phoneNumber != null && phoneNumber.isNotEmpty)
                      _buildRow('Numéro cible', phoneNumber),
                    if (commissionSic != null && commissionSic > 0)
                      _buildRow('Frais / Comm. SIC', FcfaFormatter.format(commissionSic)),
                  ],
                ),
              ),

              // --- COMPENSATIONS (SI DISPONIBLE) ---
              if (compensationDetails != null && compensationDetails.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Déduction puces float (Compensation)',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.TableHelper.fromTextArray(
                  headers: ['Puce', 'Opérateur', 'Montant'],
                  headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  data: compensationDetails.map((detail) {
                    final phone = detail['phone'] ?? detail['pucePhone'] ?? '-';
                    final op = detail['operator'] ?? detail['puceOperator'] ?? '-';
                    final amt = (detail['amount'] ?? detail['amountDeducted'] ?? 0.0) as double;
                    return [phone.toString(), op.toString(), FcfaFormatter.format(amt)];
                  }).toList(),
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  cellPadding: const pw.EdgeInsets.all(4),
                ),
              ],

              pw.Spacer(),

              // --- QR CODE & PIED DE PAGE ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Reçu officiel émis par SIC',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: darkColor,
                        ),
                      ),
                      pw.Text(
                        'Conservez ce reçu comme preuve de paiement.',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'SIC-TX:$transactionId',
                    width: 44,
                    height: 44,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Ouvre l'interface d'impression système ou de choix de l'imprimante Bluetooth/Wi-Fi.
  static Future<void> printReceipt({
    required String transactionId,
    required String title,
    required double amount,
    required String status,
    required DateTime createdAt,
    double? commissionSic,
    String? operatorName,
    String? phoneNumber,
    List<Map<String, dynamic>>? compensationDetails,
  }) async {
    final pdfBytes = await buildReceiptPdf(
      transactionId: transactionId,
      title: title,
      amount: amount,
      status: status,
      createdAt: createdAt,
      commissionSic: commissionSic,
      operatorName: operatorName,
      phoneNumber: phoneNumber,
      compensationDetails: compensationDetails,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Recu_SIC_$transactionId.pdf',
    );
  }

  /// Ouvre la feuille de partage native de l'OS (WhatsApp, Mail, Fichiers...).
  static Future<void> shareReceipt({
    required String transactionId,
    required String title,
    required double amount,
    required String status,
    required DateTime createdAt,
    double? commissionSic,
    String? operatorName,
    String? phoneNumber,
    List<Map<String, dynamic>>? compensationDetails,
  }) async {
    final pdfBytes = await buildReceiptPdf(
      transactionId: transactionId,
      title: title,
      amount: amount,
      status: status,
      createdAt: createdAt,
      commissionSic: commissionSic,
      operatorName: operatorName,
      phoneNumber: phoneNumber,
      compensationDetails: compensationDetails,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Recu_SIC_${_shortId(transactionId)}.pdf',
    );
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1E293B'),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortId(String id) =>
      id.length <= 12 ? id : '${id.substring(0, 12)}…';
}
