import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:plan_sync/core/services/api_client.dart';

/// Builds a real [ApiClient] (no [ApiClient.initialize] needed in tests)
/// with a one-shot Dio interceptor pre-installed.

ApiClient fakeApiClientWith({
  required String responseBody,
  int statusCode = 200,
}) {
  final client = ApiClient();
  client.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: statusCode,
            data: responseBody,
          ),
        );
      },
    ),
  );
  return client;
}

ApiClient fakeApiClientWithError() {
  final client = ApiClient();
  client.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(
          DioException.connectionError(
            requestOptions: options,
            reason: 'Fake network error',
          ),
        );
      },
    ),
  );
  return client;
}

/// Serves different bodies based on which URL suffix is matched.
/// [urlToBody] maps a URL substring to the JSON string to return.
ApiClient fakeApiClientByUrl(Map<String, String> urlToBody) {
  final client = ApiClient();
  client.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final url = options.uri.toString();
        final match = urlToBody.entries.firstWhere(
          (e) => url.contains(e.key),
          orElse: () => MapEntry('__none__', '{}'),
        );
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: match.value,
          ),
        );
      },
    ),
  );
  return client;
}

String encodeSectionsJson() => jsonEncode({
      '2024': {
        'SEM1': {'A16': 'A-16', 'B16': 'B-16'},
        'SEM2': {'A16': 'A-16'},
      },
      '2023': {
        'SEM1': {'A16': 'A-16'},
      },
    });

String encodeElectivesJson() => jsonEncode({
      '2024': {
        'SEM1': {'a': 'Scheme A', 'b': 'Scheme B'},
        'SEM2': {'a': 'Scheme A'},
      },
    });

String encodeTimetableJson({bool isTimetableUpdating = false}) =>
    jsonEncode({
      'meta': {
        'section': 'b16',
        'type': 'norm-class',
        'revision': 'Revision 1.03',
        'effective-date': 'Jan 15, 2024',
        'contributor': 'Admin',
        'isTimetableUpdating': isTimetableUpdating,
      },
      'data': {
        'monday': [
          {'time': '08:00 - 09:00', 'subject': 'Math', 'room': '301'},
        ],
        'tuesday': [
          {'time': '09:00 - 10:00', 'subject': 'Physics', 'room': '302'},
        ],
      },
    });
