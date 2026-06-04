import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pulse_ops/pulse_ops.dart';

late final Dio dio;

// ── Demo PulseEventExporter ──────────────────────────────────────────────────
//
// In a real app replace `debugPrint` with your analytics SDK
// (Mixpanel, Amplitude, your own backend, etc.).
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
  // Swap InMemoryNetworkStore for FileBackedNetworkStore to survive restarts.
  // Records are restored from disk on initialize() and written on every capture.
  final networkStore = FileBackedNetworkStore(maxRecords: 200);
  await networkStore.initialize();

  await PulseOps.initialize(
    config: const PulseOpsConfig(
      maxRecords: 200,
      sanitizeKeys: ['authorization', 'token', 'password', 'cookie'],
      // Memory monitoring is on by default — tune here if needed:
      enableMemoryMonitor: true,
      memorySampleIntervalSeconds: 2,
      memorySnapshotBufferSize: 120,
    ),
    // ── Persistent store ────────────────────────────────────────────────────
    networkStore: networkStore,
    // ── Unified event exporter ───────────────────────────────────────────────
    // Receives every failed request AND every crash in one place.
    eventExporter: _DemoEventExporter(),
    // crashReporter: FirebaseCrashReporterAdapter(FirebaseCrashlytics.instance),
  );

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
  // Tracks controllers we intentionally leak for demo purposes.
  final List<TextEditingController> _leakedControllers = [];

  // A properly managed controller — disposed in dispose().
  final TextEditingController _managedController = TextEditingController();

  @override
  void dispose() {
    _managedController.dispose();
    // _leakedControllers are intentionally NOT disposed here to trigger leak
    // detection in the Memory screen.
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
    } catch (_) {
      // Error forwarded to _DemoEventExporter.onFailedRequest automatically.
    }
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

  /// Creates a controller and immediately disposes it — no leak.
  void _allocateAndDispose(BuildContext context) {
    final c = TextEditingController();
    c.dispose();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Created & disposed — not a leak')),
    );
  }

  /// Creates a controller but never disposes it — shows up as a leak after 30s.
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

  /// Manually records a rebuild so the Memory screen shows rebuild frequency.
  void _triggerRebuild() {
    PulseOps.instance.memoryStore.recordRebuild('_HomeScreen');
    setState(() {}); // force a real rebuild too
  }

  @override
  Widget build(BuildContext context) {
    // Record every rebuild so the Memory screen can track frequency.
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
              'network traffic, performance, and memory.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),

            // ── Network ───────────────────────────────────────────────────
            const _SectionLabel('🌐 Network'),
            _DemoButton(
                label: 'GET /posts/1', onPressed: _get),
            _DemoButton(
                label: 'POST /posts (sanitized header)', onPressed: _post),
            _DemoButton(
                label: 'Failing GET → triggers event exporter',
                onPressed: _failing,
                danger: true),
            _DemoButton(
                label: 'Multipart upload', onPressed: _multipart),
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
            _DemoButton(
              label: 'Open Memory screen',
              onPressed: () => PulseOps.instance.openInspector(context),
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
              label: 'Open Inspector',
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
                backgroundColor: danger
                    ? cs.error.withValues(alpha: 0.15)
                    : null,
                foregroundColor: danger ? cs.error : null,
              ),
              child: Text(label),
            ),
    );
  }
}
