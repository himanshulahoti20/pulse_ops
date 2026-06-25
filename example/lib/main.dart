import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pulse_ops/pulse_ops.dart';

late final Dio dio;

// ── Demo PulseEventExporter ──────────────────────────────────────────────────
//
// In a real app replace `debugPrint` with your analytics SDK.
class _DemoEventExporter implements PulseEventExporter {
  @override
  Future<void> onFailedRequest(NetworkRecord record) async {
    debugPrint(
      '[PulseExporter] ❌ ${record.method} ${record.url} '
      '→ ${record.statusCode ?? record.error}',
    );
  }

  @override
  Future<void> onCrash(
    Object error,
    StackTrace? stackTrace, {
    required String? reason,
    required bool fatal,
    required List<Breadcrumb> breadcrumbs,
    required List<NetworkRecord> recentRequests,
  }) async {
    debugPrint(
      '[PulseExporter] 💥 ${fatal ? 'FATAL' : 'non-fatal'}: $error '
      '(${breadcrumbs.length} breadcrumbs, '
      '${recentRequests.length} recent requests)',
    );
  }
}

// ── Bootstrap ────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Persistent network store ──────────────────────────────────────────────
  final networkStore = FileBackedNetworkStore(maxRecords: 200);
  await networkStore.initialize();

  await PulseOps.initialize(
    config: const PulseOpsConfig(
      maxRecords: 200,
      sanitizeKeys: ['authorization', 'token', 'password', 'cookie'],
      enableMemoryMonitor: true,
      memorySampleIntervalSeconds: 2,
      memorySnapshotBufferSize: 120,
      // Enable the test observability screen in the inspector.
      enableTestObservability: true,
      maxTestSessions: 50,
    ),
    networkStore: networkStore,
    eventExporter: _DemoEventExporter(),
  );

  // ── Test Observability ────────────────────────────────────────────────────
  // Attach the test store once so PulseTestObserver.beginTest() / endTest()
  // work everywhere.  In real test files you do this in setUpAll().
  PulseTestObserver.attach(PulseOps.instance.testStore);

  dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'))
    ..interceptors.add(PulseOps.instance.dioInterceptor);

  runApp(PulseOps.instance.wrap(retryDio: dio, child: const _ExampleApp()));
}

// ── App shell ─────────────────────────────────────────────────────────────────

class _ExampleApp extends StatelessWidget {
  const _ExampleApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PulseOps Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF7C5CFF),
        brightness: Brightness.dark,
      ),
      home: const _HomeScreen(),
    );
  }
}

// ── Home screen ───────────────────────────────────────────────────────────────

class _HomeScreen extends StatefulWidget {
  const _HomeScreen();

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  final List<TextEditingController> _leakedControllers = [];
  final TextEditingController _managedController = TextEditingController();

  // Tracks whether a test session is currently active.
  bool _testActive = false;

  @override
  void dispose() {
    _managedController.dispose();
    super.dispose();
  }

  // ── Network ───────────────────────────────────────────────────────────────

  Future<void> _get() => dio.get<dynamic>('/posts/1');

  Future<void> _post() => dio.post<dynamic>(
        '/posts',
        data: {'title': 'PulseOps', 'body': 'Hello', 'userId': 1},
        options: Options(headers: {'authorization': 'Bearer secret-token'}),
      );

  Future<void> _failing() async {
    try {
      await dio.get<dynamic>('/this-endpoint-does-not-exist');
    } catch (_) {}
  }

  Future<void> _multipart() async {
    final form = FormData.fromMap({
      'name': 'pulse',
      'file': MultipartFile.fromString('hello', filename: 'note.txt'),
    });
    try {
      await dio.post<dynamic>('/upload', data: form);
    } catch (_) {}
  }

  // ── Crash ─────────────────────────────────────────────────────────────────

  void _crash(BuildContext context) {
    PulseOps.instance.log('User tapped Crash button');
    PulseOps.instance.recordError(
      Exception('Manual crash for demo'),
      StackTrace.current,
      reason: 'demo button',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Reported to crash backend + event exporter')),
    );
  }

  // ── Memory ────────────────────────────────────────────────────────────────

  void _allocateAndDispose(BuildContext context) {
    final c = TextEditingController();
    c.dispose();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Created & disposed — not a leak')),
    );
  }

  void _allocateLeak(BuildContext context) {
    _leakedControllers.add(TextEditingController());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Created undisposed controller '
          '(${_leakedControllers.length} total) — '
          'check Memory screen after 30 s',
        ),
      ),
    );
  }

  void _triggerRebuild() {
    PulseOps.instance.memoryStore.recordRebuild('_HomeScreen');
    setState(() {});
  }

  // ── Test Observability ────────────────────────────────────────────────────

  /// Simulates a complete passing test: begin → log → API call → assertion → end.
  Future<void> _simulatePassingTest(BuildContext context) async {
    setState(() => _testActive = true);

    PulseTestObserver.beginTest('fetch post returns 200', group: 'Network');
    PulseTestObserver.log('Arranging: setting up Dio client');

    // Fire a real API call — captured by the test session automatically
    // because PulseDioInterceptor records it, and we forward it via the
    // network store listener set up below.
    try {
      final response = await dio.get<dynamic>('/posts/1');
      PulseTestObserver.assertion(
        'status code is 200',
        passed: response.statusCode == 200,
      );
      PulseTestObserver.assertion(
        'response body is a Map',
        passed: response.data is Map,
      );
    } catch (e) {
      PulseTestObserver.assertion('request succeeds', passed: false);
    }

    PulseTestObserver.pump(frameCount: 2);

    // Capture a simulated performance reading.
    PulseTestObserver.capturePerformance(fps: 59.4, droppedFrames: 1);

    // Capture the latest network record into the test session.
    final records = PulseOps.instance.store.records;
    if (records.isNotEmpty) {
      PulseTestObserver.captureNetworkRequest(records.first);
    }

    PulseTestObserver.endTest();
    setState(() => _testActive = false);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Passing test session recorded — open Tests tab')),
    );
  }

  /// Simulates a failing test with a failure message and stack trace.
  Future<void> _simulateFailingTest(BuildContext context) async {
    setState(() => _testActive = true);

    PulseTestObserver.beginTest('user can log in', group: 'Auth');
    PulseTestObserver.log('Arranging: loading login screen');
    PulseTestObserver.pump(frameCount: 1);

    PulseTestObserver.log('Acting: tapping login button');
    PulseTestObserver.pump(duration: const Duration(milliseconds: 300));

    PulseTestObserver.assertion('login button is visible', passed: true);
    PulseTestObserver.assertion(
      'welcome text appears after login',
      passed: false,
    );

    PulseTestObserver.endTest(
      passed: false,
      failureMessage: "Expected: exactly one widget with text 'Welcome'\n"
          "  Actual: no widgets found with text 'Welcome'",
      stackTrace: "#0  expect (package:flutter_test/src/expect.dart:168)\n"
          "#1  _HomeScreenState._simulateFailingTest (example/lib/main.dart)\n"
          "#2  _DemoButton.onPressed (example/lib/main.dart)",
    );

    setState(() => _testActive = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Failing test session recorded — open Tests tab')),
    );
  }

  /// Runs a mini suite: three tests in sequence.
  Future<void> _simulateSuite(BuildContext context) async {
    setState(() => _testActive = true);

    // Test 1 — pass
    PulseTestObserver.beginTest('GET /posts returns list', group: 'Posts API');
    PulseTestObserver.log('Fetching posts endpoint');
    try {
      final r = await dio.get<dynamic>('/posts?_limit=3');
      PulseTestObserver.assertion('status 200', passed: r.statusCode == 200);
      PulseTestObserver.assertion('returns a list', passed: r.data is List);
      if (PulseOps.instance.store.records.isNotEmpty) {
        PulseTestObserver.captureNetworkRequest(
            PulseOps.instance.store.records.first);
      }
    } catch (_) {
      PulseTestObserver.assertion('request succeeds', passed: false);
    }
    PulseTestObserver.endTest();

    // Test 2 — pass
    PulseTestObserver.beginTest('POST /posts creates entry',
        group: 'Posts API');
    PulseTestObserver.log('Posting a new record');
    try {
      final r = await dio.post<dynamic>(
        '/posts',
        data: {'title': 'test', 'body': 'body', 'userId': 99},
      );
      PulseTestObserver.assertion('status 201', passed: r.statusCode == 201);
      if (PulseOps.instance.store.records.isNotEmpty) {
        PulseTestObserver.captureNetworkRequest(
            PulseOps.instance.store.records.first);
      }
    } catch (_) {
      PulseTestObserver.assertion('post succeeds', passed: false);
    }
    PulseTestObserver.endTest();

    // Test 3 — fail (expected 204 but gets 200 from JSONPlaceholder)
    PulseTestObserver.beginTest('DELETE /posts/1 returns 204',
        group: 'Posts API');
    PulseTestObserver.log('Sending DELETE request');
    try {
      final r = await dio.delete<dynamic>('/posts/1');
      final passed = r.statusCode == 204;
      PulseTestObserver.assertion('status is 204', passed: passed);
      if (PulseOps.instance.store.records.isNotEmpty) {
        PulseTestObserver.captureNetworkRequest(
            PulseOps.instance.store.records.first);
      }
      if (!passed) {
        PulseTestObserver.endTest(
          passed: false,
          failureMessage: 'Expected status 204 but got ${r.statusCode}',
        );
      } else {
        PulseTestObserver.endTest();
      }
    } catch (_) {
      PulseTestObserver.endTest(
          passed: false, failureMessage: 'Request threw an exception');
    }

    setState(() => _testActive = false);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Suite complete (3 tests) — open Tests tab')),
    );
  }

  @override
  Widget build(BuildContext context) {
    PulseOps.instance.memoryStore.recordRebuild('_HomeScreen');

    return Scaffold(
      appBar: AppBar(title: const Text('PulseOps Demo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tap the floating button or use "Open Inspector" to explore '
              'network traffic, performance, memory, and test sessions.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),

            // ── Network ───────────────────────────────────────────────────
            const _SectionLabel('🌐 Network'),
            _DemoButton(label: 'GET /posts/1', onPressed: _get),
            _DemoButton(
                label: 'POST /posts (sanitized header)', onPressed: _post),
            _DemoButton(
                label: 'Failing GET → triggers event exporter',
                onPressed: _failing,
                danger: true),
            _DemoButton(label: 'Multipart upload', onPressed: _multipart),
            const SizedBox(height: 24),

            // ── Memory ────────────────────────────────────────────────────
            const _SectionLabel('🧠 Memory'),
            _DemoButton(
              label: 'Allocate & dispose (clean)',
              onPressed: () => _allocateAndDispose(context),
            ),
            _DemoButton(
              label: 'Allocate without dispose → leak after 30 s',
              onPressed: () => _allocateLeak(context),
              danger: true,
            ),
            _DemoButton(
              label: 'Force rebuild (increments counter)',
              onPressed: _triggerRebuild,
            ),
            const SizedBox(height: 24),

            // ── Test Observability ────────────────────────────────────────
            const _SectionLabel('🧪 Test Observability'),
            if (_testActive)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Test session running…',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            _DemoButton(
              label: 'Simulate passing test (with real API call)',
              onPressed:
                  _testActive ? () {} : () => _simulatePassingTest(context),
            ),
            _DemoButton(
              label: 'Simulate failing test (with assertions)',
              onPressed:
                  _testActive ? () {} : () => _simulateFailingTest(context),
              danger: true,
            ),
            _DemoButton(
              label: 'Run mini suite (3 tests, 1 fails)',
              onPressed: _testActive ? () {} : () => _simulateSuite(context),
            ),
            const SizedBox(height: 24),

            // ── Crash & diagnostics ───────────────────────────────────────
            const _SectionLabel('💥 Crash & Diagnostics'),
            _DemoButton(
              label: 'Report non-fatal error',
              onPressed: () => _crash(context),
              outlined: true,
            ),
            _DemoButton(
              label: 'Open Inspector  (→ tap 🧪 for tests)',
              onPressed: () =>
                  PulseOps.instance.openInspector(context, retryDio: dio),
              outlined: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 0.4,
          ),
        ),
      );
}

class _DemoButton extends StatelessWidget {
  const _DemoButton({
    required this.label,
    required this.onPressed,
    this.danger = false,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool danger;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = danger ? cs.error : cs.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(foregroundColor: color),
              child: Text(label),
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor:
                    danger ? cs.error.withValues(alpha: 0.15) : null,
                foregroundColor: danger ? cs.error : null,
              ),
              child: Text(label),
            ),
    );
  }
}
