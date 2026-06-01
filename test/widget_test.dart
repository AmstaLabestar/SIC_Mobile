import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/main.dart';

void main() {
  testWidgets('should render SIC Mobile architecture preview', (tester) async {
    await tester.pumpWidget(const SicMobileApp());

    expect(find.text('SIC Mobile'), findsOneWidget);
    expect(find.textContaining('FCFA'), findsOneWidget);
  });
}
