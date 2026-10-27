import 'dart:async';
import 'dart:convert';
import 'dart:io';

class FirebaseAccountService {
  static const _projectId = 'ids-service-docket';
  static const _apiKey = 'AIzaSyC3qD3xTxGtyCY_CFeMA5gOSyMqyHFeCvE';

  Future<bool> containsEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents:runQuery',
      {'key': _apiKey},
    );
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);

    try {
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 12));
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'structuredQuery': {
            'from': [
              {'collectionId': 'accounts'},
            ],
            'where': {
              'fieldFilter': {
                'field': {'fieldPath': 'email'},
                'op': 'EQUAL',
                'value': {'stringValue': normalizedEmail},
              },
            },
            'limit': 1,
          },
        }),
      );

      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != HttpStatus.ok) {
        throw FirebaseAccountLookupException(
          _readFirebaseError(responseBody, response.statusCode),
        );
      }

      final results = jsonDecode(responseBody);
      if (results is! List) {
        throw const FirebaseAccountLookupException(
          'Firebase returned an unexpected response. Please try again.',
        );
      }
      return results.any(
        (result) => result is Map && result['document'] is Map,
      );
    } on FirebaseAccountLookupException {
      rethrow;
    } on TimeoutException {
      throw const FirebaseAccountLookupException(
        'Firebase is taking too long to respond. Check your connection and try again.',
      );
    } on SocketException {
      throw const FirebaseAccountLookupException(
        'Could not connect to Firebase. Check your internet connection and try again.',
      );
    } on FormatException {
      throw const FirebaseAccountLookupException(
        'Firebase returned an invalid response. Please try again.',
      );
    } finally {
      client.close(force: true);
    }
  }

  String _readFirebaseError(String body, int statusCode) {
    try {
      final response = jsonDecode(body);
      final message = response['error']?['message'];
      if (message is String && message.isNotEmpty) {
        return 'Firebase account check failed: $message';
      }
    } on FormatException {
      // Use the HTTP status when Firebase did not return JSON.
    }
    return 'Firebase account check failed (HTTP $statusCode).';
  }
}

class FirebaseAccountLookupException implements Exception {
  const FirebaseAccountLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}
