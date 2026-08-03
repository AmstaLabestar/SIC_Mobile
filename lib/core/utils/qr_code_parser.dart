/// Résultat du décodage d'un contenu de QR Code.
class ParsedQrData {
  const ParsedQrData({
    this.phoneNumber,
    this.operatorCode,
    this.rawText,
  });

  final String? phoneNumber;
  final String? operatorCode;
  final String? rawText;

  bool get hasPhone => phoneNumber != null && phoneNumber!.isNotEmpty;

  @override
  String toString() => 'ParsedQrData(phone: $phoneNumber, op: $operatorCode)';
}

/// Analyseur intelligent de contenus QR Code (format brut, vCard, coordonnées SIC, préfixes TEL).
class QrCodeParser {
  const QrCodeParser._();

  /// Analyse une chaîne brute issue d'un scan QR Code et extrait le numéro et l'opérateur.
  static ParsedQrData parse(String rawContent) {
    final cleaned = rawContent.trim();
    if (cleaned.isEmpty) return const ParsedQrData();

    String? phone;
    String? opCode;

    // 1. Détection via Regex d'un numéro de téléphone (8 à 15 chiffres, avec ou sans +226 / 00226)
    final phoneRegex = RegExp(r'(?:\+226|00226)?\s*([0-9]{8,12})');
    final match = phoneRegex.firstMatch(cleaned);

    if (match != null) {
      phone = match.group(1);
    } else {
      // Fallback : extraire tous les chiffres si la chaîne ressemble à un numéro
      final digits = cleaned.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 8 && digits.length <= 15) {
        phone = digits;
      }
    }

    // 2. Détection de l'opérateur si présent dans le texte ou dérivable du numéro
    final lower = cleaned.toLowerCase();
    if (lower.contains('orange') || lower.contains(' om ') || lower.contains('om:')) {
      opCode = 'OM';
    } else if (lower.contains('moov')) {
      opCode = 'MOOV';
    } else if (lower.contains('telecel')) {
      opCode = 'TELECEL';
    } else if (lower.contains('mtn')) {
      opCode = 'MTN';
    } else if (lower.contains('wave')) {
      opCode = 'WAVE';
    }

    // 3. Déduction par préfixe de numéro au Burkina Faso (si opCode non spécifié)
    if (phone != null && phone.length == 8 && opCode == null) {
      opCode = _guessOperatorFromPrefix(phone);
    }

    return ParsedQrData(
      phoneNumber: phone,
      operatorCode: opCode,
      rawText: cleaned,
    );
  }

  /// Déduit l'opérateur selon le préfixe téléphonique standard au Burkina Faso.
  static String? _guessOperatorFromPrefix(String phone) {
    final prefix2 = phone.substring(0, 2);
    // Orange : 07, 57, 67, 77, 56, 66, 76...
    const orangePrefixes = {'07', '57', '67', '77', '56', '66', '76', '06', '54', '64', '74'};
    // Moov : 01, 51, 61, 71, 02, 52, 62, 72, 03, 53, 63, 73, 60, 70...
    const moovPrefixes = {'01', '51', '61', '71', '02', '52', '62', '72', '03', '53', '63', '73', '60', '70'};
    // Telecel : 05, 55, 65, 75...
    const telecelPrefixes = {'05', '55', '65', '75', '68', '78'};

    if (orangePrefixes.contains(prefix2)) return 'OM';
    if (moovPrefixes.contains(prefix2)) return 'MOOV';
    if (telecelPrefixes.contains(prefix2)) return 'TELECEL';

    return null;
  }
}
