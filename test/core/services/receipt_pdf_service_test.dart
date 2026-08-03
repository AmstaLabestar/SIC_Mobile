import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/core/services/receipt_pdf_service.dart';

void main() {
  test('buildReceiptPdf génère des octets PDF valides', () async {
    final bytes = await ReceiptPdfService.buildReceiptPdf(
      transactionId: 'TX1234567890',
      title: 'Dépôt Orange Money',
      amount: 50000,
      status: 'SUCCESS',
      createdAt: DateTime(2026, 8, 2, 14, 30),
      commissionSic: 500,
      operatorName: 'Orange Money',
      phoneNumber: '70123456',
      compensationDetails: [
        {
          'phone': '70123456',
          'operator': 'Orange',
          'amount': 50000.0,
        }
      ],
    );

    expect(bytes, isNotEmpty);
    // Vérifier l'en-tête PDF standard (%PDF-)
    final pdfHeader = String.fromCharCodes(bytes.take(4));
    expect(pdfHeader, equals('%PDF'));
  });
}
