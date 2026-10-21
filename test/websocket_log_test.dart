import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ops/pulse_ops.dart';

void main() {
  group('WebSocketLogStore', () {
    test('logs, decodes and sanitizes messages newest first', () {
      final store = WebSocketLogStore(sanitizer: Sanitizer(['token']));
      final s = store.open('wss://example.com/ws');
      s.sent('{"token":"abc","a":1}');
      s.received('pong');
      s.received([1, 2, 3]);

      expect(s.messages.first.data, '<binary 3 bytes>');
      expect(s.messages[1].data, 'pong');
      expect((s.messages.last.data as Map)['token'],
          Sanitizer.redactedPlaceholder);
      expect(s.sentCount, 1);
      expect(s.receivedCount, 2);
      store.dispose();
    });

    test('bounds messages and sessions', () {
      final store = WebSocketLogStore(maxSessions: 2, maxMessagesPerSession: 2);
      final s = store.open('a');
      for (var i = 0; i < 5; i++) {
        s.sent('$i');
      }
      expect(s.messages.map((m) => m.data), ['4', '3']);
      store.open('b');
      store.open('c');
      expect(store.sessions.map((e) => e.url), ['c', 'b']);
      store.dispose();
    });

    test('trackIncoming forwards data and closes the session', () async {
      final store = WebSocketLogStore();
      final s = store.open('a');
      final out =
          await s.trackIncoming(Stream.fromIterable(['x', 'y'])).toList();
      expect(out, ['x', 'y']);
      expect(s.receivedCount, 2);
      expect(s.isOpen, isFalse);
      store.dispose();
    });

    test('stream replays current sessions first', () async {
      final store = WebSocketLogStore()..open('a');
      expect((await store.stream.first).single.url, 'a');
      store.dispose();
    });
  });
}
