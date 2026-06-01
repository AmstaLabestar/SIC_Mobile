import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/main.dart';

void main() {
  testWidgets('should render dashboard with mocked summary', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SicMobileApp()));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Bonjour, Kone'), findsOneWidget);
    expect(find.text('Solde total'), findsOneWidget);
    expect(find.text('Mes soldes'), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
