/// Raccourcis USSD — opérations **même réseau**, exécutées nativement par
/// l'opérateur (pas d'agrégateur, pas de frais SIC).
///
/// Modèle : `[opérateur][opération] -> gabarit`. Le gabarit contient des
/// placeholders `{amount}` / `{recipient}` remplis par [UssdShortcuts.build].
/// L'utilisateur valide ensuite avec son **code secret** dans la session USSD.
///
/// Pays couvert : **Burkina Faso** (Orange Money `*144*…`, Moov Money `*555*…`).
/// L'extension multi-pays se fera en ajoutant une clé pays au registre.
library;

/// Opérations pouvant passer par un raccourci USSD (même réseau).
enum UssdOperation {
  /// Recharge de crédit sur SA propre ligne (montant inline dans le code).
  rechargeSelf,

  /// Transfert d'argent vers un numéro (destinataire inline ; le montant est
  /// saisi dans la session USSD, pas dans le code).
  transfer,

  /// Retrait / cash-out : le CLIENT envoie de l'argent au CODE MARCHAND de la
  /// SIM de l'agent (puis saisit son PIN). Placeholders `{merchant}` + `{amount}`.
  cashout,
}

/// Registre des gabarits USSD + constructeur du code final.
class UssdShortcuts {
  const UssdShortcuts._();

  /// Burkina Faso : gabarits par opérateur (code backend) puis opération.
  static const Map<String, Map<UssdOperation, String>> _burkina = {
    'ORANGE': {
      UssdOperation.rechargeSelf: '*144*1*1*{amount}#',
      UssdOperation.transfer: '*144*2*1*{recipient}#',
      // Retrait client : *144*3*<code marchand>*<montant># (Orange Money BF).
      UssdOperation.cashout: '*144*3*{merchant}*{amount}#',
    },
    'MOOV': {
      // Même logique qu'Orange, préfixe *555* — sous-menus À CONFIRMER.
      UssdOperation.rechargeSelf: '*555*1*1*{amount}#',
      UssdOperation.transfer: '*555*2*1*{recipient}#',
      // NB : code cash-out Moov non confirmé -> volontairement absent (supports()
      // renverra false, l'appelant retombera sur l'agrégateur / affichage manuel).
    },
  };

  /// Vrai si un raccourci existe pour cet opérateur + opération.
  static bool supports(String operator, UssdOperation op) =>
      _template(operator, op) != null;

  /// Construit le code USSD final (placeholders remplis), ou `null` si
  /// l'opérateur/l'opération n'est pas couvert (→ l'appelant retombe sur
  /// l'agrégateur ou affiche une indisponibilité).
  static String? build(
    String operator,
    UssdOperation op, {
    int? amount,
    String? recipient,
    String? merchant,
  }) {
    final template = _template(operator, op);
    if (template == null) return null;
    return template
        .replaceAll('{amount}', amount?.toString() ?? '')
        .replaceAll('{recipient}', (recipient ?? '').trim())
        .replaceAll('{merchant}', (merchant ?? '').trim());
  }

  static String? _template(String operator, UssdOperation op) =>
      _burkina[operator.toUpperCase()]?[op];
}
