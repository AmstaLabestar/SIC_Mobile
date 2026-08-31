import 'operator_detector.dart';

/// Canal d'exécution d'une opération (envoi d'argent / recharge).
enum OperationRoute {
  /// **Même réseau** → raccourci USSD natif (opérateur), **0 frais SIC**.
  ussdShortcut,

  /// **Réseaux différents** → agrégateur (overlay pay-in/pay-out), **avec frais**.
  aggregator,
}

/// Décide par quel canal passe une opération, selon les réseaux source/destination.
///
/// Règle unique : même opérateur → USSD (natif, gratuit) ; opérateurs différents
/// → agrégateur (seul capable de franchir les réseaux, avec frais SIC).
/// Vaut pour les agents ET les clients.
class OperationRouter {
  const OperationRouter._();

  /// Décide à partir d'opérateurs déjà connus (ex. SIM agent + n° destinataire).
  static OperationRoute decide(String sourceOperator, String destOperator) =>
      sourceOperator.toUpperCase() == destOperator.toUpperCase()
          ? OperationRoute.ussdShortcut
          : OperationRoute.aggregator;

  /// Décide à partir des NUMÉROS (détecte les opérateurs). Utile pour un client
  /// (source = son propre numéro). Retourne `null` si un opérateur ne peut pas
  /// être déterminé (numéro invalide/inconnu) → l'appelant demande de préciser.
  static OperationRoute? decideFromNumbers(
    String sourceNumber,
    String destNumber,
  ) {
    final src = OperatorDetector.fromNumber(sourceNumber);
    final dst = OperatorDetector.fromNumber(destNumber);
    if (src == null || dst == null) return null;
    return decide(src, dst);
  }
}
