import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ops/pulse_ops.dart';

void main() {
  group('Sanitizer', () {
    final sanitizer = Sanitizer(const ['authorization', 'password', 'token']);

    test('redacts sensitive headers case-insensitively', () {
      final headers = sanitizer.sanitizeHeaders({
        'Authorization': 'Bearer abc',
        'Content-Type': 'application/json',
        'X-Trace-Id': 'trace-1',
      });
      expect(headers['Authorization'], Sanitizer.redactedPlaceholder);
      expect(headers['Content-Type'], 'application/json');
      expect(headers['X-Trace-Id'], 'trace-1');
    });

    test('redacts nested body values', () {
      final body = sanitizer.sanitizeBody({
        'user': {
          'email': 'a@b.c',
          'password': 'super-secret',
          'meta': {
            'token': 'abc.def',
            'safe': 1,
          }
        },
        'list': [
          {'password': 'x', 'value': 1},
          {'value': 2},
        ],
      }) as Map;

      expect((body['user'] as Map)['password'], Sanitizer.redactedPlaceholder);
      expect(((body['user'] as Map)['meta'] as Map)['token'],
          Sanitizer.redactedPlaceholder);
      expect(((body['user'] as Map)['meta'] as Map)['safe'], 1);
      expect((body['list'] as List).first['password'],
          Sanitizer.redactedPlaceholder);
      expect((body['list'] as List).last['value'], 2);
    });

    test('leaves null and non-map bodies untouched', () {
      expect(sanitizer.sanitizeBody(null), isNull);
      expect(sanitizer.sanitizeBody('plain string'), 'plain string');
      expect(sanitizer.sanitizeBody(42), 42);
    });
  });
}
