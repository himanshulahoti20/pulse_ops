import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ops/pulse_ops.dart';

void main() {
  group('NetworkLogExporter', () {
    const exporter = NetworkLogExporter();

    final older = NetworkRecord(
      id: '1',
      method: 'GET',
      url: 'https://api.example.com/a',
      startedAt: DateTime.utc(2026, 1, 1),
      endedAt: DateTime.utc(2026, 1, 1, 0, 0, 0, 120),
      statusCode: 200,
      status: NetworkStatus.success,
      requestHeaders: const {'accept': 'application/json'},
      responseBody: const {'ok': true},
    );

    final newer = NetworkRecord(
      id: '2',
      method: 'POST',
      url: 'https://api.example.com/b',
      startedAt: DateTime.utc(2026, 1, 2),
      endedAt: DateTime.utc(2026, 1, 2, 0, 0, 0, 50),
      statusCode: 500,
      status: NetworkStatus.error,
      requestBody: const {'payload': 1},
      error: 'boom',
    );

    test('JSON export emits chronological array with full payloads', () {
      final out = exporter.export([newer, older]);
      final decoded = jsonDecode(out) as List;
      expect(decoded.length, 2);
      expect(decoded.first['id'], '1');
      expect(decoded.last['id'], '2');
      expect(decoded.last['error'], 'boom');
    });

    test('text export contains method, URL, and bodies', () {
      final out = exporter.export([older], format: LogExportFormat.text);
      expect(out, contains('GET https://api.example.com/a'));
      expect(out, contains('Result: success'));
      expect(out, contains('"ok": true'));
    });

    test('curl export concatenates one command per record', () {
      final out = exporter.export([older, newer], format: LogExportFormat.curl);
      expect(out.split('curl').length - 1, 2);
      expect(out, contains('https://api.example.com/a'));
      expect(out, contains('https://api.example.com/b'));
    });
  });
}
