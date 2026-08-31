import '../network/operator_mapping.dart';

class Validators {
  const Validators._();

  static const List<String> _countryCodes = ['+226', '226', '+225', '225'];

  /// Retire l'indicatif (+226/+225) et la ponctuation -> numero national.
  static String normalizePhone(String value) {
    var phone = value.trim().replaceAll(RegExp(r'[\s\-.()]'), '');
    for (final code in _countryCodes) {
      if (phone.startsWith(code)) {
        return phone.substring(code.length);
      }
    }
    if (phone.startsWith('+')) {
      phone = phone.substring(1);
    }
    return phone;
  }

  static const Map<String, List<String>> _bfPrefixes = {
    'ORANGE': ['04', '05', '06', '07', '44', '54', '55', '56', '57', '64', '65', '66', '67', '74', '75', '76', '77'],
    'MOOV': ['01', '02', '03', '50', '51', '52', '53', '60', '61', '62', '63', '70', '71', '72', '73'],
    'TELECEL': ['58', '59', '68', '69', '78', '79'],
  };

  static const Map<String, List<String>> _ciPrefixes = {
    'ORANGE': ['07', '08', '09'],
    'MOOV': ['01', '02', '03'],
    'MTN': ['05', '06', '04'],
  };

  /// Valide un numero pour un operateur (code mobile : OM/MOOV/TELECEL/MTN/WAVE/SANK/CORIS).
  static String? validateOperatorPhone(String? value, String operatorCode) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return 'Le numéro est obligatoire.';
    }

    final national = normalizePhone(raw);
    if (!RegExp(r'^\d+$').hasMatch(national)) {
      return 'Le numéro ne doit contenir que des chiffres.';
    }

    final backend = OperatorMapping.toBackend(operatorCode);
    final bfPrefixList = _bfPrefixes[backend];
    final ciPrefixList = _ciPrefixes[backend];

    // Pour les operateurs agnostiques (Wave, Sank, Coris) sans restriction de prefixe reseau
    if (bfPrefixList == null && ciPrefixList == null) {
      if (national.length == 8 || national.length == 10) {
        return null;
      }
      return 'Le numéro doit comporter 8 ou 10 chiffres.';
    }

    final okBf = national.length == 8 && bfPrefixList != null && bfPrefixList.any((p) => national.startsWith(p));
    final okCi = national.length == 10 && ciPrefixList != null && ciPrefixList.any((p) => national.startsWith(p));

    if (okBf || okCi) {
      return null;
    }

    if (national.length != 8 && national.length != 10) {
      return 'Le numéro doit comporter 8 ou 10 chiffres.';
    }

    return 'Numéro non valide pour l\'opérateur sélectionné.';
  }

  /// Valide un numero sans operateur precise : accepte s'il correspond a
  /// l'un des operateurs connus (Burkina 8 chiffres / Cote d'Ivoire 10).
  static String? validateAnyPhone(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return 'Le numero est obligatoire.';
    }
    final national = normalizePhone(raw);
    if (!RegExp(r'^\d+$').hasMatch(national)) {
      return 'Le numero ne doit contenir que des chiffres.';
    }

    if (national.length == 8) {
      final isBfValid = _bfPrefixes.values.any((list) => list.any((p) => national.startsWith(p)));
      if (isBfValid) return null;
    } else if (national.length == 10) {
      final isCiValid = _ciPrefixes.values.any((list) => list.any((p) => national.startsWith(p)));
      if (isCiValid) return null;
    }

    return 'Numéro ou préfixe non valide.';
  }

  static String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Le numero est obligatoire.';
    }

    final phoneRegex = RegExp(r'^(01|05|07)\d{8}$');
    if (!phoneRegex.hasMatch(phone)) {
      return 'Entrez un numero valide de 10 chiffres.';
    }

    return null;
  }

  static String? validateAmount(String? value) {
    final rawValue = value?.trim().replaceAll(' ', '') ?? '';

    if (rawValue.isEmpty) {
      return 'Le montant est obligatoire.';
    }

    final amount = double.tryParse(rawValue.replaceAll(',', '.'));
    if (amount == null) {
      return 'Entrez un montant valide.';
    }

    if (amount < 100) {
      return 'Le montant minimum est 100 FCFA.';
    }

    if (amount > 2000000) {
      return 'Le montant maximum est 2 000 000 FCFA.';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est obligatoire.';
    }

    return null;
  }
}
