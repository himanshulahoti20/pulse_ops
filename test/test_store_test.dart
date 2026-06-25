import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ops/pulse_ops.dart';

void main() {
  group('TestStore', () {
    late TestStore store;

    setUp(() => store = TestStore());
    tearDown(() => store.dispose());

    test('beginSession creates a running session', () {
      final session = store.beginSession('my test');
      expect(session.name, 'my test');
      expect(session.status, TestSessionStatus.running);
      expect(store.activeSession, isNotNull);
      expect(store.sessions, hasLength(1));
    });

    test('endSession marks session as passed', () {
      store.beginSession('passes');
      store.endSession();
      expect(store.sessions.first.status, TestSessionStatus.passed);
      expect(store.activeSession, isNull);
    });

    test('endSession marks session as failed with message', () {
      store.beginSession('fails');
      store.endSession(
        passed: false,
        failureMessage: 'Expected true',
        stackTrace: '#0 main',
      );
      final s = store.sessions.first;
      expect(s.status, TestSessionStatus.failed);
      expect(s.failureMessage, 'Expected true');
      expect(s.stackTrace, '#0 main');
    });

    test('logEvent appends to active session', () {
      store.beginSession('with events');
      store.logEvent('step one');
      store.logEvent('step two');
      expect(store.activeSession!.events, hasLength(2));
      expect(store.activeSession!.events.first.message, 'step one');
    });

    test('logEvent is a no-op without an active session', () {
      store.logEvent('orphan');
      expect(store.sessions, isEmpty);
    });

    test('recordNetworkRequest attaches to session and logs a network event',
        () {
      store.beginSession('net test');
      final record = NetworkRecord(
        id: '1',
        method: 'GET',
        url: 'https://api.example.com/users',
        startedAt: DateTime.now(),
        endedAt: DateTime.now(),
        statusCode: 200,
        status: NetworkStatus.success,
      );
      store.recordNetworkRequest(record);
      final s = store.activeSession!;
      expect(s.networkRequests, hasLength(1));
      expect(s.events.where((e) => e.type == TestEventType.networkRequest),
          hasLength(1));
    });

    test('recordPerformance appends a performance event', () {
      store.beginSession('fps test');
      store.recordPerformance(fps: 58.3, droppedFrames: 2);
      final event = store.activeSession!.events.single;
      expect(event.type, TestEventType.performance);
      expect(event.data?['fps'], 58.3);
      expect(event.data?['dropped_frames'], 2);
    });

    test('sessions list is bounded by maxSessions', () {
      final bounded = TestStore(maxSessions: 3);
      for (int i = 0; i < 5; i++) {
        bounded.beginSession('test $i');
        bounded.endSession();
      }
      expect(bounded.sessions, hasLength(3));
      bounded.dispose();
    });

    test('clear empties sessions and active session', () {
      store.beginSession('to be cleared');
      store.clear();
      expect(store.sessions, isEmpty);
      expect(store.activeSession, isNull);
    });

    test('stream emits after each mutation', () async {
      final emissions = <int>[];
      final sub = store.stream.listen((s) => emissions.add(s.length));
      store.beginSession('a');
      store.endSession();
      store.beginSession('b');
      await Future<void>.delayed(Duration.zero);
      sub.cancel();
      expect(emissions, [1, 1, 2]);
    });
  });

  group('PulseTestObserver', () {
    late TestStore store;

    setUp(() {
      store = TestStore();
      PulseTestObserver.attach(store);
    });

    tearDown(() {
      PulseTestObserver.detach();
      store.dispose();
    });

    test('attach / detach wires the store', () {
      expect(PulseTestObserver.store, same(store));
      PulseTestObserver.detach();
      expect(PulseTestObserver.store, isNull);
    });

    test('beginTest throws when no store attached', () {
      PulseTestObserver.detach();
      expect(
        () => PulseTestObserver.beginTest('x'),
        throwsStateError,
      );
    });

    test('beginTest / endTest round-trip', () {
      PulseTestObserver.beginTest('round-trip', group: 'g');
      PulseTestObserver.log('msg');
      PulseTestObserver.assertion('value == 1');
      PulseTestObserver.pump(frameCount: 3);
      PulseTestObserver.endTest();

      final s = store.sessions.single;
      expect(s.name, 'round-trip');
      expect(s.group, 'g');
      expect(s.isPassed, isTrue);
      expect(s.events, hasLength(3));
      expect(s.events[0].type, TestEventType.log);
      expect(s.events[1].type, TestEventType.assertion);
      expect(s.events[2].type, TestEventType.widgetPump);
    });
  });
}
