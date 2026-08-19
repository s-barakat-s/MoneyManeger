import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../firebase/firebase_providers.dart';
import 'backend_config.dart';

final backendHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final authenticatedBackendClientProvider = Provider<AuthenticatedBackendClient>(
  (ref) => AuthenticatedBackendClient(
    auth: ref.watch(firebaseAuthProvider),
    client: ref.watch(backendHttpClientProvider),
  ),
);

class AuthenticatedBackendClient {
  const AuthenticatedBackendClient({
    required FirebaseAuth auth,
    required http.Client client,
  }) : _auth = auth,
       _client = client;

  final FirebaseAuth _auth;
  final http.Client _client;

  Future<Map<String, dynamic>> get(String path) {
    return _send(method: 'GET', path: path);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, Object?> body,
  }) {
    return _send(method: 'POST', path: path, body: body);
  }

  Future<Map<String, dynamic>> _send({
    required String method,
    required String path,
    Map<String, Object?>? body,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final user = _auth.currentUser;
      if (user == null) {
        throw const BackendApiException(
          statusCode: 401,
          code: 'unauthenticated',
          message: 'Authentication is required.',
        );
      }
      final token = await user.getIdToken(attempt == 1);
      if (token == null || token.isEmpty) {
        throw const BackendApiException(
          statusCode: 401,
          code: 'unauthenticated',
          message: 'A Firebase ID token is unavailable.',
        );
      }

      final request = http.Request(method, BackendConfig.endpoint(path));
      request.headers['authorization'] = 'Bearer $token';
      request.headers['accept'] = 'application/json';
      if (body != null) {
        request.headers['content-type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 401 && attempt == 0) continue;
      return _decode(response);
    }

    throw const BackendApiException(
      statusCode: 401,
      code: 'unauthenticated',
      message: 'Authentication could not be refreshed.',
    );
  }

  Map<String, dynamic> _decode(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw BackendApiException(
        statusCode: response.statusCode,
        code: 'invalid-response',
        message: 'The backend returned an invalid response.',
      );
    }
    if (decoded is! Map) {
      throw BackendApiException(
        statusCode: response.statusCode,
        code: 'invalid-response',
        message: 'The backend returned an invalid response.',
      );
    }
    final envelope = Map<String, dynamic>.from(decoded);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        envelope['ok'] == true) {
      final data = envelope['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      throw BackendApiException(
        statusCode: response.statusCode,
        code: 'invalid-response',
        message: 'The backend response is missing data.',
      );
    }

    final rawError = envelope['error'];
    final error = rawError is Map
        ? Map<String, dynamic>.from(rawError)
        : const <String, dynamic>{};
    final code = error['code'];
    final message = error['message'];
    throw BackendApiException(
      statusCode: response.statusCode,
      code: code is String && code.isNotEmpty ? code : 'backend-error',
      message: message is String && message.isNotEmpty
          ? message
          : 'The backend request failed.',
    );
  }
}

class BackendApiException implements Exception {
  const BackendApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  final int statusCode;
  final String code;
  final String message;

  @override
  String toString() => 'BackendApiException($code, HTTP $statusCode)';
}
