import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Stockage securise des jetons JWT (access / refresh) et metadonnees
/// biometriques (identifiant d'appareil stable + activation).
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _kAccess = 'sic_access_token';
  static const _kRefresh = 'sic_refresh_token';
  static const _kDeviceId = 'sic_biometric_device_id';
  static const _kBioEnabled = 'sic_biometric_enabled';

  Future<SharedPreferences> get _webStorage => SharedPreferences.getInstance();

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    if (kIsWeb) {
      final prefs = await _webStorage;
      await prefs.setString(_kAccess, access);
      await prefs.setString(_kRefresh, refresh);
    } else {
      await _storage.write(key: _kAccess, value: access);
      await _storage.write(key: _kRefresh, value: refresh);
    }
  }

  Future<void> saveAccess(String access) async {
    if (kIsWeb) {
      final prefs = await _webStorage;
      await prefs.setString(_kAccess, access);
    } else {
      await _storage.write(key: _kAccess, value: access);
    }
  }

  Future<String?> readAccess() async {
    if (kIsWeb) {
      final prefs = await _webStorage;
      return prefs.getString(_kAccess);
    } else {
      return _storage.read(key: _kAccess);
    }
  }

  Future<String?> readRefresh() async {
    if (kIsWeb) {
      final prefs = await _webStorage;
      return prefs.getString(_kRefresh);
    } else {
      return _storage.read(key: _kRefresh);
    }
  }

  Future<bool> hasSession() async => (await readRefresh()) != null;

  /// Efface uniquement les jetons de session (la biometrie reste activee :
  /// l'agent pourra se reconnecter par empreinte).
  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await _webStorage;
      await prefs.remove(_kAccess);
      await prefs.remove(_kRefresh);
    } else {
      await _storage.delete(key: _kAccess);
      await _storage.delete(key: _kRefresh);
    }
  }

  // --- Biometrie ---------------------------------------------------------

  /// Identifiant d'appareil stable (UUID genere une fois, persiste).
  /// Sert de cle d'enregistrement aupres du backend biometrique.
  Future<String> getOrCreateDeviceId() async {
    if (kIsWeb) {
      final prefs = await _webStorage;
      final existing = prefs.getString(_kDeviceId);
      if (existing != null && existing.isNotEmpty) return existing;
      final id = const Uuid().v4();
      await prefs.setString(_kDeviceId, id);
      return id;
    } else {
      final existing = await _storage.read(key: _kDeviceId);
      if (existing != null && existing.isNotEmpty) return existing;
      final id = const Uuid().v4();
      await _storage.write(key: _kDeviceId, value: id);
      return id;
    }
  }

  Future<bool> isBiometricEnabled() async {
    if (kIsWeb) {
      final prefs = await _webStorage;
      return prefs.getBool(_kBioEnabled) ?? false;
    } else {
      return (await _storage.read(key: _kBioEnabled)) == 'true';
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (kIsWeb) {
      final prefs = await _webStorage;
      await prefs.setBool(_kBioEnabled, enabled);
    } else {
      await _storage.write(key: _kBioEnabled, value: enabled ? 'true' : 'false');
    }
  }
}
