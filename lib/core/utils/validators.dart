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

  /// Valide un numero pour un operateur (code mobile : OM/MOOV/TELECEL/MTN).
  static String? validateOperatorPhone(String? value, String operatorCode) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return 'Le numero est obligatoire.';
    }

    final national = normalizePhone(raw);
    if (!RegExp(r'^\d+$').hasMatch(national)) {
      return 'Le numero ne doit contenir que des chiffres.';
    }

    final backend = OperatorMapping.toBackend(operatorCode);
    final hasBf = ['ORANGE', 'MOOV', 'TELECEL'].contains(backend);
    final hasCi = ['ORANGE', 'MOOV', 'MTN'].contains(backend);

    final okBf = hasBf && national.length == 8;
    final okCi = hasCi && national.length == 10;

    if (okBf || okCi) {
      return null;
    }

    if (hasBf && !hasCi) {
      return 'Le numero doit comporter 8 chiffres.';
    }
    if (hasCi && !hasBf) {
      return 'Le numero doit comporter 10 chiffres.';
    }
    return 'Le numero doit comporter 8 ou 10 chiffres.';
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
    if (national.length == 8 || national.length == 10) {
      return null;
    }
    return 'Le numero doit comporter 8 ou 10 chiffres.';
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
