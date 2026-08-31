import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/core/network/network_providers.dart';
import 'package:sic_mobile/core/storage/token_storage.dart';
import 'package:sic_mobile/features/auth/presentation/screens/register_screen.dart';

/// Stockage de tokens vide (pas de plugin natif en test).
class _EmptyTokenStorage extends TokenStorage {
  _EmptyTokenStorage() : super(const FlutterSecureStorage());
  @override
  Future<bool> hasSession() async => false;
  @override
  Future<String?> readAccess() async => null;
  @override
  Future<String?> readRefresh() async => null;
}

Widget _harness({required bool isAgent}) => ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(_EmptyTokenStorage()),
      ],
      child: MaterialApp(home: RegisterScreen(isAgent: isAgent)),
    );

void main() {
  testWidgets(
      'le champ Code marchand est visible pour un Agent, masque pour un Client',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Cas Agent
    await tester.pumpWidget(_harness(isAgent: true));
    await tester.pump();
    
    // Remplir Étape 0 pour continuer
    await tester.enterText(find.byType(TextFormField).at(0), 'testagent');
    await tester.enterText(find.byType(TextFormField).at(1), 'agent@test.com');
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Code marchand'), findsOneWidget);

    // Cas Client
    await tester.pumpWidget(_harness(isAgent: false));
    await tester.pump();

    // Remplir Étape 0 pour continuer
    await tester.enterText(find.byType(TextFormField).at(0), 'testclient');
    await tester.enterText(find.byType(TextFormField).at(1), 'client@test.com');
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Code marchand'), findsNothing);
  });
}
