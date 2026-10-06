import 'dart:async';
import 'package:http/http.dart' as http;

/// Bounds the entire HTTP exchange, including the response body. Mutations
/// are never retried here: the server may have committed before a timeout.
class DeadlineClient extends http.BaseClient {
  final http.Client _inner;
  final Duration deadline;
  DeadlineClient({
    http.Client? inner,
    this.deadline = const Duration(seconds: 20),
  }) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await (() async {
      final stream = await _inner.send(request);
      return http.Response.fromStream(stream);
    })().timeout(deadline);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      contentLength: response.bodyBytes.length,
      request: response.request,
      reasonPhrase: response.reasonPhrase,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
    );
  }

  @override
  void close() => _inner.close();
}
