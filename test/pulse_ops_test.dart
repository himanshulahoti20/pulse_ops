import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ops/pulse_ops.dart';

void main() {
  // FpsTracker calls WidgetsBinding.instance — binding must be initialised
  // before any test that calls PulseOps.initialize().
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PulseOps facade', () {
    tearDown(() => PulseOps.reset());

    test('throws when accessed before initialization', () {
      expect(() => PulseOps.instance, throwsStateError);
    });

    test('initialize is idempotent and exposes services', () async {
      final a = await PulseOps.initialize(
        config: const PulseOpsConfig(maxRecords: 10, enableInRelease: true),
      );
      final b = await PulseOps.initialize();
      expect(identical(a, b), isTrue);
      expect(PulseOps.isInitialized, isTrue);
      expect(a.store, isA<NetworkStore>());
      expect(a.dioInterceptor, isNotNull);
    });

    test('shorthand flags are applied to the effective config', () async {
      final p = await PulseOps.initialize(
        enableInRelease: true,
        sanitizeKeys: ['x-secret'],
      );
      expect(p.config.enableInRelease, isTrue);
      expect(p.config.sanitizeKeys, contains('x-secret'));
    });
  });
}
