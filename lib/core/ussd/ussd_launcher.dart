import 'package:url_launcher/url_launcher.dart';

import 'ussd_codes.dart';

/// Lance un raccourci USSD — **option A** : ouvre le composeur pré-rempli ;
/// l'utilisateur appuie sur Appeler puis valide avec son **code secret**.
///
/// (Une exécution 100 % en arrière-plan — option B — nécessiterait un plugin
/// USSD natif Android + la permission `CALL_PHONE` ; à envisager plus tard.)
class UssdLauncher {
  const UssdLauncher._();

  /// Chaîne `tel:` prête pour le composeur : le `#` est encodé en `%23`,
  /// le `*` reste tel quel.
  static String telUriString(String ussdCode) =>
      'tel:${ussdCode.replaceAll('#', '%23')}';

  /// Construit puis ouvre le raccourci USSD pour [operator] + [op].
  ///
  /// Retourne `false` si l'opérateur/l'opération n'est pas couvert (→ l'appelant
  /// bascule sur l'agrégateur) ou si le composeur ne peut pas être ouvert.
  static Future<bool> launch(
    String operator,
    UssdOperation op, {
    int? amount,
    String? recipient,
  }) async {
    final code = UssdShortcuts.build(
      operator,
      op,
      amount: amount,
      recipient: recipient,
    );
    if (code == null) return false;
    final uri = Uri.parse(telUriString(code));
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }
}
