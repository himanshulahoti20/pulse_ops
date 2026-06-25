// Example test file demonstrating PulseOps Test Observability integration.
//
// Run with:   flutter test
//
// After running, open the inspector in a debug build and tap the 🧪 button to
// see the captured sessions, event timelines, and network calls.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:pulse_ops/pulse_ops.dart';

// ---------------------------------------------------------------------------
// Lightweight stub adapter — no real HTTP requests during tests.
// ---------------------------------------------------------------------------
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._responder);

  final ResponseBody Function(RequestOptions) _responder;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      _responder(options);
}

// ---------------------------------------------------------------------------
// Shared setup
// ---------------------------------------------------------------------------

late Dio _dio;

Future<void> _boot() async {
  // Initialize PulseOps (idempotent — safe to call multiple times).
  await PulseOps.initialize(
    config: const PulseOpsConfig(
      enableInRelease: true, // needed so monitoring runs in test mode
      enableTestObservability: true,
    ),
  );

  // Attach the observer once so all tests in this file can share it.
  PulseTestObserver.attach(PulseOps.instance.testStore);

  _dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..interceptors.add(PulseOps.instance.dioInterceptor);
}

// ---------------------------------------------------------------------------
// Test suite
// ---------------------------------------------------------------------------

void main() {
  // One-time setup — boots PulseOps and wires the test observer.
  setUpAll(_boot);

  // Tear down after each test so the store stays clean between runs.
  tearDownAll(() async {
    PulseTestObserver.detach();
    await PulseOps.reset();
  });

  // ── Example widget test ──────────────────────────────────────────────────

  group('Counter widget', () {
    setUp(() => PulseTestObserver.beginTest(
          'counter increments on tap',
          group: 'Counter widget',
        ));

    tearDown(() => PulseTestObserver.endTest());

    testWidgets('increments counter on FAB tap', (tester) async {
      PulseTestObserver.log('Pumping counter widget');
      await tester.pumpWidget(
        const MaterialApp(home: _CounterWidget()),
      );
      PulseTestObserver.pump(frameCount: 1);

      PulseTestObserver.assertion('initial count is 0');
      expect(find.text('0'), findsOneWidget);

      PulseTestObserver.log('Tapping the + FAB');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      PulseTestObserver.pump(frameCount: 1);

      PulseTestObserver.assertion('count incremented to 1');
      expect(find.text('1'), findsOneWidget);
    });
  });

  // ── Network-aware test ────────────────────────────────────────────────────

  group('Posts API', () {
    setUp(() => PulseTestObserver.beginTest(
          'GET /posts/1 returns post',
          group: 'Posts API',
        ));

    tearDown(() => PulseTestObserver.endTest());

    test('fetches a post successfully', () async {
      _dio.httpClientAdapter = _StubAdapter(
        (_) => ResponseBody.fromString(
          '{"id":1,"title":"PulseOps","body":"test","userId":1}',
          200,
          headers: {
            'content-type': ['application/json'],
          },
        ),
      );

      PulseTestObserver.log('Calling GET /posts/1');
      final response = await _dio.get<dynamic>('/posts/1');

      // Forward the captured record to the test session.
      final records = PulseOps.instance.store.records;
      if (records.isNotEmpty) {
        PulseTestObserver.captureNetworkRequest(records.first);
      }

      PulseTestObserver.assertion('status code is 200',
          passed: response.statusCode == 200);
      expect(response.statusCode, 200);

      PulseTestObserver.assertion('title field is present',
          passed: (response.data as Map).containsKey('title'));
      expect((response.data as Map)['title'], 'PulseOps');
    });

    test('handles 404 correctly', () async {
      _dio.httpClientAdapter = _StubAdapter(
        (_) => ResponseBody.fromString('{"error":"not found"}', 404),
      );

      Object? caught;
      try {
        await _dio.get<dynamic>('/posts/9999');
      } catch (e) {
        caught = e;
      }

      final records = PulseOps.instance.store.records;
      if (records.isNotEmpty) {
        PulseTestObserver.captureNetworkRequest(records.first);
      }

      PulseTestObserver.assertion('request throws DioException',
          passed: caught is DioException);
      expect(caught, isA<DioException>());
    });
  });

  // ── Failure diagnostics demo ──────────────────────────────────────────────

  group('Failure diagnostics', () {
    test('records failure message and stack trace', () {
      PulseTestObserver.beginTest('deliberately failing test',
          group: 'Diagnostics');

      PulseTestObserver.log('About to fail intentionally');
      PulseTestObserver.assertion('this assertion always fails', passed: false);

      PulseTestObserver.endTest(
        passed: false,
        failureMessage:
            "Expected: <true>\n  Actual: <false>\n  Which: was false",
        stackTrace: StackTrace.current.toString(),
      );

      // Verify the session was recorded correctly.
      final sessions = PulseOps.instance.testStore.sessions;
      expect(sessions, isNotEmpty);
      final s = sessions.first;
      expect(s.isFailed, isTrue);
      expect(s.failureMessage, contains('Expected'));
    });
  });

  // ── Performance snapshot demo ─────────────────────────────────────────────

  group('Performance', () {
    setUp(() => PulseTestObserver.beginTest(
          'FPS stays above 55 during scroll',
          group: 'Performance',
        ));

    tearDown(() => PulseTestObserver.endTest());

    testWidgets('records FPS snapshot into test session', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ListView.builder(
            itemCount: 50,
            itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
          ),
        ),
      );

      // Simulate the kind of performance data you'd collect from
      // PerformanceStore during a real scroll test.
      PulseTestObserver.capturePerformance(fps: 59.1, droppedFrames: 1);
      PulseTestObserver.pump(duration: const Duration(milliseconds: 500));

      final session = PulseOps.instance.testStore.activeSession!;
      final perfEvents = session.events
          .where((e) => e.type == TestEventType.performance)
          .toList();

      expect(perfEvents, hasLength(1));
      expect(perfEvents.first.data?['fps'], 59.1);
    });
  });
}

// ---------------------------------------------------------------------------
// Minimal counter widget for the widget test
// ---------------------------------------------------------------------------

class _CounterWidget extends StatefulWidget {
  const _CounterWidget();

  @override
  State<_CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<_CounterWidget> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('$_count')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _count++),
        child: const Icon(Icons.add),
      ),
    );
  }
}
