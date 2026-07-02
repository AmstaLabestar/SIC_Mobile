import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/core/utils/fcfa_formatter.dart';

void main() {
  group('FcfaFormatter', () {
    test('format ajoute FCFA et formate les milliers', () {
      expect(FcfaFormatter.format(75000), '75\u202f000 FCFA');
      expect(FcfaFormatter.format(0), '0 FCFA');
      expect(FcfaFormatter.format(100), '100 FCFA');
    });

    test('formatCompact affiche K pour les milliers', () {
      expect(FcfaFormatter.formatCompact(85000), '85K FCFA');
      expect(FcfaFormatter.formatCompact(85300), '85,30K FCFA');
    });

    test('formatCompact affiche M pour les millions', () {
      expect(FcfaFormatter.formatCompact(1500000), '1,50M FCFA');
      expect(FcfaFormatter.formatCompact(2000000), '2M FCFA');
    });

    test('formatCompact garde le format normal pour les petits montants', () {
      expect(FcfaFormatter.formatCompact(500), '500 FCFA');
    });

    test('formatBenefit ajoute + pour les montants positifs', () {
      expect(FcfaFormatter.formatBenefit(12500), '+ 12\u202f500 FCFA');
    });

    test('formatBenefit ajoute - pour les montants negatifs', () {
      expect(FcfaFormatter.formatBenefit(-12500), '- 12\u202f500 FCFA');
    });
  });
}
