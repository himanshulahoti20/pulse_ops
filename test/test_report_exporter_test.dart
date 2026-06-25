import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ops/pulse_ops.dart';

void main() {
  const exporter = TestReportExporter();

  TestSession makeSession({
    required String name,
    required TestSessionStatus status,
    String? failureMessage,
  }) {
    final now = DateTime(2026, 6, 25, 12);
    return TestSession(
      id: name,
      name: name,
      startedAt: now,
      endedAt: now.add(const Duration(milliseconds: 123)),
      status: status,
      failureMessage: failureMessage,
      events: [
        TestEvent(
          type: TestEventType.log,
          message: 'step 1',
          timestamp: now,
        ),
      ],
    );
  }

  group('TestReportExporter', () {
    test('JSON export includes summary and sessions', () {
      final sessions = [
        makeSession(name: 'a', status: TestSessionStatus.passed),
        makeSession(
          name: 'b',
          status: TestSessionStatus.failed,
          failureMessage: 'oops',
        ),
      ];
      final output = exporter.export(sessions, format: TestReportFormat.json);
      final decoded = jsonDecode(output) as Map<String, dynamic>;

      expect(decoded['summary']['total'], 2);
      expect(decoded['summary']['passed'], 1);
      expect(decoded['summary']['failed'], 1);
      expect(decoded['sessions'], hasLength(2));
    });

    test('JSON sessions are ordered oldest first', () {
      final earlier = TestSession(
        id: 'e',
        name: 'early',
        startedAt: DateTime(2026, 6, 25, 10),
        status: TestSessionStatus.passed,
      );
      final later = TestSession(
        id: 'l',
        name: 'late',
        startedAt: DateTime(2026, 6, 25, 11),
        status: TestSessionStatus.passed,
      );
      final output = exporter.export([later, earlier]);
      final sessions = (jsonDecode(output) as Map)['sessions'] as List<dynamic>;
      expect((sessions[0] as Map)['name'], 'early');
      expect((sessions[1] as Map)['name'], 'late');
    });

    test('text export contains pass/fail summary', () {
      final sessions = [
        makeSession(name: 'ok', status: TestSessionStatus.passed),
        makeSession(
            name: 'bad',
            status: TestSessionStatus.failed,
            failureMessage: 'boom'),
      ];
      final output = exporter.export(sessions, format: TestReportFormat.text);
      expect(output, contains('Total: 2'));
      expect(output, contains('Passed: 1'));
      expect(output, contains('Failed: 1'));
      expect(output, contains('[PASS]'));
      expect(output, contains('[FAIL]'));
      expect(output, contains('Failure: boom'));
    });

    test('empty sessions produces valid JSON', () {
      final output = exporter.export([]);
      final decoded = jsonDecode(output) as Map<String, dynamic>;
      expect(decoded['summary']['total'], 0);
      expect(decoded['summary']['pass_rate'], '–');
      expect(decoded['sessions'], isEmpty);
    });
  });
}
