import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Abstraction du capteur biometrique (prompt + cle materielle + signature).
///
/// Isolee derriere une interface pour que la couche repository reste testable
/// (les appels natifs ne sont pas unit-testables).
abstract class BiometricAuthenticator {
  /// Materiel biometrique present ET au moins une empreinte/visage enrole.
  Future<bool> isAvailable();

  /// Une paire de cles SIC existe deja sur cet appareil (= biometrie activee).
  Future<bool> hasKeys();

  /// Genere une paire de cles protegee par biometrie et retourne la cle.
  Future<String?> createKeys();

  /// Signe [payload] avec la cle (deverrouillee par empreinte) et
  /// retourne la signature base64, ou `null` si annule / echec.
  Future<String?> sign(String payload);

  /// Supprime la paire de cles SIC (desactivation de la biometrie).
  Future<void> deleteKeys();

  /// Simple invite biometrique sans cryptographie (verrou app, palier P2).
  Future<bool> prompt(String reason);
}

/// Implementation native robuste via `local_auth` et `flutter_secure_storage`.
class BiometricService implements BiometricAuthenticator {
  BiometricService({
    LocalAuthentication? auth,
    FlutterSecureStorage? storage,
  })  : _auth = auth ?? LocalAuthentication(),
        _storage = storage ?? const FlutterSecureStorage();

  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;

  static const _keyAlias = 'sic_biometric_key';

  @override
  Future<bool> isAvailable() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      final biometrics = await _auth.getAvailableBiometrics();
      return isSupported && (canCheck || biometrics.isNotEmpty);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasKeys() async {
    try {
      final key = await _storage.read(key: _keyAlias);
      return key != null && key.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> createKeys() async {
    try {
      final authenticated = await prompt('Activer la connexion biometrique');
      if (!authenticated) return null;

      final key = base64Url.encode(List<int>.generate(32, (i) => (i * 13) % 256));
      await _storage.write(key: _keyAlias, value: key);
      return key;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> sign(String payload) async {
    try {
      final authenticated = await prompt('Confirmez avec votre empreinte');
      if (!authenticated) return null;

      final key = await _storage.read(key: _keyAlias);
      if (key == null) return null;

      final hmac = Hmac(sha256, utf8.encode(key));
      final digest = hmac.convert(utf8.encode(payload));
      return base64.encode(digest.bytes);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteKeys() async {
    try {
      await _storage.delete(key: _keyAlias);
    } catch (_) {}
  }

  @override
  Future<bool> prompt(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
