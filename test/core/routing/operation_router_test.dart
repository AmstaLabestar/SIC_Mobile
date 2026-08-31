import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/core/routing/operation_router.dart';

void main() {
  group('OperationRouter.decide', () {
    test('meme operateur -> raccourci USSD', () {
      expect(OperationRouter.decide('ORANGE', 'ORANGE'),
          OperationRoute.ussdShortcut);
      expect(OperationRouter.decide('orange', 'ORANGE'),
          OperationRoute.ussdShortcut);
    });

    test('operateurs differents -> agregateur', () {
      expect(OperationRouter.decide('ORANGE', 'MOOV'),
          OperationRoute.aggregator);
    });
  });

  group('OperationRouter.decideFromNumbers', () {
    test('meme reseau (Orange -> Orange) -> USSD', () {
      expect(OperationRouter.decideFromNumbers('07123456', '76543210'),
          OperationRoute.ussdShortcut);
    });

    test('reseaux differents (Orange -> Moov) -> agregateur', () {
      expect(OperationRouter.decideFromNumbers('07123456', '70123456'),
          OperationRoute.aggregator);
    });

    test('numero indetectable -> null', () {
      expect(OperationRouter.decideFromNumbers('07123456', '99123456'), isNull);
    });
  });
}
