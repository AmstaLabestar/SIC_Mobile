import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/core/network/network_providers.dart';
import 'package:sic_mobile/core/storage/token_storage.dart';
import 'package:sic_mobile/features/client/presentation/screens/client_home_screen.dart';

class _EmptyTokenStorage extends TokenStorage {
  _EmptyTokenStorage() : super(const FlutterSecureStorage());
  @override
  Future<bool> hasSession() async => false;
  @override
  Future<String?> readAccess() async => null;
  @override
  Future<String?> readRefresh() async => null;
}

Widget _harness() => ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(_EmptyTokenStorage()),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ClientHomeScreen()),
      ),
    );

void main() {
  testWidgets('l\'accueil client affiche les 4 actions rapides et la carte du solde',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Solde total'), findsOneWidget);
    expect(find.text('Envoyer'), findsOneWidget);
    expect(find.text('Recevoir'), findsOneWidget);
    expect(find.text('Convertir'), findsOneWidget);
    expect(find.text('Sécurité'), findsOneWidget);
  });

  testWidgets('toucher Recevoir affiche la feuille de réception avec QR code', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byIcon(Icons.qr_code_scanner_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Recevoir des fonds'), findsOneWidget);
  });
}
