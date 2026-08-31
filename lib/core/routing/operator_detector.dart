/// Détection de l'opérateur mobile à partir d'un numéro.
///
/// Burkina Faso : numéro national de **8 chiffres**, opérateur déterminé par les
/// **2 premiers chiffres** (préfixes disjoints — un préfixe = un seul opérateur).
/// Miroir du backend (`TransactionValidator`). Extension CI / autres pays à venir.
class OperatorDetector {
  const OperatorDetector._();

  /// Préfixes Burkina Faso par opérateur (code backend).
  static const Map<String, List<String>> _burkinaPrefixes = {
    'ORANGE': [
      '04', '05', '06', '07', '44', '54', '55', '56', '57',
      '64', '65', '66', '67', '74', '75', '76', '77',
    ],
    'MOOV': [
      '01', '02', '03', '50', '51', '52', '53',
      '60', '61', '62', '63', '70', '71', '72', '73',
    ],
    'TELECEL': ['58', '59', '68', '69', '78', '79'],
  };

  /// Retire l'indicatif (+226 / 226) et la ponctuation → numéro national.
  static String normalize(String phone) {
    var p = phone.trim().replaceAll(RegExp(r'[\s\-.()]'), '');
    for (final code in ['+226', '226']) {
      if (p.startsWith(code)) {
        p = p.substring(code.length);
        break;
      }
    }
    if (p.startsWith('+')) p = p.substring(1);
    return p;
  }

  /// Opérateur d'un numéro Burkina (8 chiffres), ou `null` si inconnu/invalide.
  static String? fromNumber(String phone) {
    final n = normalize(phone);
    if (n.length != 8) return null;
    final prefix = n.substring(0, 2);
    for (final entry in _burkinaPrefixes.entries) {
      if (entry.value.contains(prefix)) return entry.key;
    }
    return null;
  }
}
