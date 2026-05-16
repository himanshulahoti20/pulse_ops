import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ops/pulse_ops.dart';

void main() {
  group('CurlBuilder', () {
    const builder = CurlBuilder();

    NetworkRecord baseRecord({
      String method = 'GET',
      Map<String, dynamic> headers = const {},
      Object? body,
      Map<String, dynamic> query = const {},
    }) {
      return NetworkRecord(
        id: '1',
        method: method,
        url: 'https://api.example.com/v1/users',
        startedAt: DateTime.utc(2024),
        requestHeaders: headers,
        queryParameters: query,
        requestBody: body,
      );
    }

    test('omits -X for GET', () {
      final out = builder.build(baseRecord());
      expect(out, contains('curl '));
      expect(out, isNot(contains('-X GET')));
      expect(out, contains("'https://api.example.com/v1/users'"));
    });

    test('emits -X and headers and body for POST', () {
      final out = builder.build(baseRecord(
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: {'name': 'Pulse'},
      ));
      expect(out, contains('-X POST'));
      expect(out, contains("-H 'Content-Type: application/json'"));
      expect(out, contains("--data '{\"name\":\"Pulse\"}'"));
    });

    test('escapes single quotes in values', () {
      final out = builder.build(baseRecord(
        method: 'POST',
        body: "it's fine",
      ));
      expect(out, contains(r"--data 'it'\''s fine'"));
    });

    test('merges query parameters into URL', () {
      final out = builder.build(
        baseRecord(query: const {'page': 2, 'q': 'hi'}),
      );
      expect(out, contains('page=2'));
      expect(out, contains('q=hi'));
    });
  });
}
