import 'package:biometric_signature/biometric_signature.dart';

/// Abstraction du capteur biometrique (invite + cle materielle + signature).
///
/// Isolee derriere une interface pour que la couche repository reste testable
/// (les appels natifs ne sont pas unit-testables).
abstract class BiometricAuthenticator {
  /// Materiel biometrique present ET au moins une empreinte/visage enrole.
  Future<bool> isAvailable();

  /// Une paire de cles SIC existe ET est toujours valide (= biometrie activee).
  /// Renvoie `false` si l'OS a invalide la cle (nouvelle biometrie enrolee).
  Future<bool> hasKeys();

  /// Genere une paire de cles materielle protegee par biometrie et retourne la
  /// cle publique (PEM), ou `null` si annule / echec.
  Future<String?> createKeys();

  /// Signe [payload] avec la cle privee (deverrouillee par biometrie) et
  /// retourne la signature base64, ou `null` si annule / echec.
  Future<String?> sign(String payload);

  /// Supprime la paire de cles SIC (desactivation de la biometrie).
  Future<void> deleteKeys();

  /// Simple invite biometrique sans cryptographie (verrou app, palier P2).
  Future<bool> prompt(String reason);
}

/// Implementation MATERIELLE via `biometric_signature`.
///
/// La paire de cles RSA-2048 est generee et conservee dans le Keystore/StrongBox
/// (Android) ou la Secure Enclave (iOS). La cle privee ne quitte jamais le
/// materiel et n'est deverrouillable QUE par une biometrie forte. Surtout, elle
/// est **invalidee automatiquement si un nouveau doigt/visage est enrole**
/// (`setInvalidatedByBiometricEnrollment`) — ce qui neutralise le scenario
/// "appareil vole + le voleur ajoute son empreinte".
///
/// Formats alignes sur le backend (api/views/pin_biometric.py) :
/// cle publique en **PEM** (RSA), signature en **base64** (RSA PKCS#1 v1.5,
/// SHA-256). Aucune modification backend necessaire.
class BiometricService implements BiometricAuthenticator {
  BiometricService({BiometricSignature? signature})
      : _bio = signature ?? BiometricSignature();

  final BiometricSignature _bio;

  /// Alias dedie a la cle d'authentification SIC.
  static const _keyAlias = 'sic_auth_key';

  @override
  Future<bool> isAvailable() async {
    try {
      final a = await _bio.biometricAuthAvailable();
      return (a.canAuthenticate ?? false) && (a.hasEnrolledBiometrics ?? true);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasKeys() async {
    try {
      // checkValidity: true => false si l'OS a invalide la cle (nouvel enrolement).
      return await _bio.biometricKeyExists(
        keyAlias: _keyAlias,
        checkValidity: true,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> createKeys() async {
    try {
      final result = await _bio.createKeys(
        keyAlias: _keyAlias,
        keyFormat: KeyFormat.pem, // PEM => load_pem_public_key cote backend
        promptMessage: 'Activer la connexion biometrique',
        config: CreateKeysConfig(
          signatureType: SignatureType.rsa, // RSA-2048, PKCS#1 v1.5 / SHA-256
          enforceBiometric: true, // biometrie obligatoire
          setInvalidatedByBiometricEnrollment: true, // invalidee si nouvel enrolement
          useDeviceCredentials: false, // pas de repli code appareil
          failIfExists: false, // re-activation => regenere proprement
        ),
      );
      final pem = result.publicKey;
      if (pem == null || pem.isEmpty || result.error != null) return null;
      return pem;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> sign(String payload) async {
    try {
      final result = await _bio.createSignature(
        payload: payload,
        keyAlias: _keyAlias,
        signatureFormat: SignatureFormat.base64, // base64 => decode cote backend
        promptMessage: 'Confirmez avec votre biometrie',
      );
      final sig = result.signature;
      if (sig == null || sig.isEmpty || result.error != null) return null;
      return sig;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteKeys() async {
    try {
      await _bio.deleteKeys(keyAlias: _keyAlias);
    } catch (_) {}
  }

  @override
  Future<bool> prompt(String reason) async {
    try {
      final r = await _bio.simplePrompt(promptMessage: reason);
      return r.success ?? false;
    } catch (_) {
      return false;
    }
  }
}
