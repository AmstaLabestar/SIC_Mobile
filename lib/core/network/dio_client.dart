import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// Fabrique le client Dio configure (base URL, timeouts, intercepteur JWT).
Dio createDioClient({
  required TokenStorage storage,
  required void Function() onSessionExpired,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(storage: storage, onSessionExpired: onSessionExpired),
  );

  // Active le Certificate Pinning si l'URL de base utilise HTTPS
  if (ApiConstants.baseUrl.startsWith('https://')) {
    final pinnedFingerprint = ApiConstants.pinnedCertFingerprint
        .replaceAll(':', '')
        .replaceAll(' ', '')
        .toLowerCase();

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        return client;
      },
      validateCertificate: (certificate, host, port) {
        if (certificate == null) return false;
        final derBytes = certificate.der;
        final hash = sha256.convert(derBytes);
        final fingerprint = hash.toString().toLowerCase();
        return fingerprint == pinnedFingerprint;
      },
    );
  }

  return dio;
}
