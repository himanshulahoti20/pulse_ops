import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pulse_ops/pulse_ops.dart';

late final Dio dio;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PulseOps.initialize(
    config: const PulseOpsConfig(
      maxRecords: 200,
      sanitizeKeys: ['authorization', 'token', 'password', 'cookie'],
    ),
    // Wire `FirebaseCrashReporterAdapter(FirebaseCrashlytics.instance)` here
    // once Firebase is initialized in your real app.
    // crashReporter: FirebaseCrashReporterAdapter(FirebaseCrashlytics.instance),
  );

  dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'))
    ..interceptors.add(PulseOps.instance.dioInterceptor);

  runApp(PulseOps.instance.wrap(retryDio: dio, child: const _ExampleApp()));
}

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

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  Future<void> _get() => dio.get<dynamic>('/posts/1');

  Future<void> _post() => dio.post<dynamic>(
        '/posts',
        data: {'title': 'PulseOps', 'body': 'Hello', 'userId': 1},
        options: Options(headers: {'authorization': 'Bearer secret-token'}),
      );

  Future<void> _failing() => dio.get<dynamic>('/this-endpoint-does-not-exist');

  Future<void> _multipart() async {
    final form = FormData.fromMap({
      'name': 'pulse',
      'file': MultipartFile.fromString('hello', filename: 'note.txt'),
    });
    try {
      await dio.post<dynamic>('/upload', data: form);
    } catch (_) {/* expected */}
  }

  void _crash(BuildContext context) {
    PulseOps.instance.log('User tapped Crash button');
    PulseOps.instance.recordError(
      Exception('Manual crash for demo'),
      StackTrace.current,
      reason: 'demo button',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Reported a non-fatal to the crash backend')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PulseOps Demo')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tap any button, then tap the floating PulseOps button to inspect.',
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _get, child: const Text('GET /posts/1')),
            const SizedBox(height: 8),
            FilledButton(onPressed: _post, child: const Text('POST /posts')),
            const SizedBox(height: 8),
            FilledButton(
                onPressed: _failing, child: const Text('Failing GET (404)')),
            const SizedBox(height: 8),
            FilledButton(
                onPressed: _multipart, child: const Text('Multipart upload')),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => _crash(context),
              child: const Text('Report non-fatal error'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () =>
                  PulseOps.instance.openInspector(context, retryDio: dio),
              child: const Text('Open Inspector'),
            ),
          ],
        ),
      ),
    );
  }
}
