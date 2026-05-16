import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ops/pulse_ops.dart';

class _RecordingCrashReporter implements PulseCrashReporter {
  final nonFatals = <Object>[];

  @override
  Future<void> attachBreadcrumbs(List<Breadcrumb> breadcrumbs) async {}

  @override
  Future<void> attachNetworkHistory(List<NetworkRecord> records) async {}

  @override
  Future<void> recordFatal(Object error,
      {StackTrace? stackTrace, Map<String, dynamic>? context}) async {}

  @override
  Future<void> recordNonFatal(Object error,
      {StackTrace? stackTrace,
      String? reason,
      Map<String, dynamic>? context}) async {
    nonFatals.add(error);
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {}
}

/// Lightweight in-test interceptor that short-circuits Dio's request handler
/// so no real HTTP request is sent.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.responder);
  final ResponseBody Function(RequestOptions options) responder;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return responder(options);
  }
}

void main() {
  group('PulseDioInterceptor', () {
    late InMemoryNetworkStore store;
    late BreadcrumbTrail trail;
    late _RecordingCrashReporter reporter;
    late Dio dio;

    setUp(() {
      store = InMemoryNetworkStore();
      trail = BreadcrumbTrail();
      reporter = _RecordingCrashReporter();
      dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.interceptors.add(
        PulseDioInterceptor(
          store: store,
          config: const PulseOpsConfig(),
          crashReporter: reporter,
          breadcrumbs: trail,
        ),
      );
    });

    tearDown(() => store.dispose());

    test('captures successful requests', () async {
      dio.httpClientAdapter = _StubAdapter(
        (o) => ResponseBody.fromString(
          '{"ok":true}',
          200,
          headers: {
            'content-type': ['application/json']
          },
        ),
      );

      await dio.get<dynamic>('/users');
      final r = store.records.single;
      expect(r.method, 'GET');
      expect(r.statusCode, 200);
      expect(r.status, NetworkStatus.success);
      expect(r.responseBody, {'ok': true});
      expect(trail.entries.length, 2); // sent + completed
    });

    test('redacts sensitive headers in stored record', () async {
      dio.httpClientAdapter = _StubAdapter(
        (o) => ResponseBody.fromString('{}', 200),
      );

      await dio.get<dynamic>(
        '/users',
        options: Options(headers: {'authorization': 'Bearer secret'}),
      );

      final r = store.records.single;
      expect(r.requestHeaders['authorization'], Sanitizer.redactedPlaceholder);
    });

    test('captures error responses and reports non-fatal', () async {
      dio.httpClientAdapter = _StubAdapter(
        (o) => ResponseBody.fromString('{"error":"nope"}', 500),
      );

      try {
        await dio.get<dynamic>('/explode');
      } on DioException {
        // expected
      }

      final r = store.records.single;
      expect(r.status, NetworkStatus.error);
      expect(r.statusCode, 500);
      expect(reporter.nonFatals, isNotEmpty);
    });
  });
}
