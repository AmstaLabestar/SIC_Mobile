import 'package:dio/dio.dart';

import '../errors/failures.dart';

/// Convertit une erreur Dio en [Failure] typee pour la couche presentation.
///
/// Securite : on n'expose JAMAIS le corps brut d'une reponse a l'utilisateur.
/// Un serveur en erreur peut renvoyer une page HTML (trace, chemins, versions) ;
/// l'afficher fuiterait des details techniques. On ne reprend donc un message
/// que s'il provient d'une reponse JSON structuree (Map), et pour les 5xx on
/// affiche un message generique.
Failure mapDioErrorToFailure(Object error) {
  if (error is! DioException) {
    return const ServerFailure('Une erreur inattendue est survenue.');
  }

  final response = error.response;
  final statusCode = response?.statusCode;

  // 1. Extraire le message d'erreur de la reponse JSON
  final jsonMsg = _jsonMessage(response?.data);

  // 2. Gestion selon le code statut HTTP s'il est present
  if (statusCode != null) {
    if (statusCode == 401) return const AuthFailure();
    if (statusCode == 403) return ServerFailure(jsonMsg ?? 'Acces refuse.', 403);
    if (statusCode == 404) return const NotFoundFailure();

    if (statusCode >= 400 && statusCode < 500) {
      return ValidationFailure(
        jsonMsg ?? 'Donnees invalides. Verifiez votre saisie.',
      );
    }

    if (statusCode >= 500) {
      return ServerFailure(
        'Service momentanement indisponible (Erreur $statusCode).',
        statusCode,
      );
    }
  }

  // 3. Gestion des erreurs de connexion reseau (sans reponse du serveur)
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      // Timeout = probleme reseau (pas de reponse serveur) -> NetworkFailure.
      return const NetworkFailure('Delai de connexion depasse. Verifiez votre reseau.');
    case DioExceptionType.connectionError:
      final raw = error.error?.toString() ?? error.message ?? '';
      return NetworkFailure(
        raw.isNotEmpty
            ? 'Connexion au serveur impossible : $raw'
            : 'Connexion au serveur impossible. Verifiez votre acces Internet.',
      );
    case DioExceptionType.cancel:
      return const ServerFailure('Requete annulee.');
    case DioExceptionType.badCertificate:
      return const ServerFailure('Connexion non securisee (Certificat SSL).');
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
    case DioExceptionType.transformTimeout:
      break;
  }

  final rawMsg = error.error?.toString() ?? error.message ?? '';
  if (rawMsg.contains('CERTIFICATE') || rawMsg.contains('Handshake')) {
    return const ServerFailure('Connexion non securisee (Certificat SSL).');
  }

  return const NetworkFailure();
}

/// Extrait un message de reponse d'erreur.
String? _jsonMessage(Object? data) {
  if (data == null) return null;
  if (data is String && data.isNotEmpty && !data.startsWith('<')) {
    return data;
  }
  if (data is List && data.isNotEmpty) {
    final first = data.first;
    if (first is String && first.isNotEmpty) return first;
    if (first is Map) return _jsonMessage(first);
  }
  if (data is Map) {
    final direct = data['message'] ?? data['detail'] ?? data['error'];
    if (direct is String && direct.isNotEmpty) return direct;
    if (direct is List && direct.isNotEmpty) return direct.first.toString();

    for (final value in data.values) {
      if (value is List && value.isNotEmpty) {
        final item = value.first;
        if (item is String && item.isNotEmpty) return item;
        if (item is Map) {
          final subMsg = _jsonMessage(item);
          if (subMsg != null) return subMsg;
        }
      }
      if (value is String && value.isNotEmpty) return value;
    }
  }
  return null;
}
