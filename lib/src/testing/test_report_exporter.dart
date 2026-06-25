import 'dart:convert';

import 'test_session.dart';

/// Output format for [TestReportExporter.export].
enum TestReportFormat {
  /// Pretty-printed JSON with a summary header and per-session detail.
  json,

  /// Human-readable text — one block per session with its events and
  /// network log.
  text,
}

/// Serialises captured [TestSession]s into shareable reports.
///
/// Sessions are emitted in chronological order (oldest first) regardless of
/// the store's insertion order.
class TestReportExporter {
  const TestReportExporter();

  String export(
    Iterable<TestSession> sessions, {
    TestReportFormat format = TestReportFormat.json,
  }) {
    final ordered = sessions.toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    switch (format) {
      case TestReportFormat.json:
        return _toJson(ordered);
      case TestReportFormat.text:
        return _toText(ordered);
    }
  }

  String _toJson(List<TestSession> sessions) {
    final passed = sessions.where((s) => s.isPassed).length;
    final failed = sessions.where((s) => s.isFailed).length;
    final total = sessions.length;
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'generated_at': DateTime.now().toIso8601String(),
      'summary': <String, dynamic>{
        'total': total,
        'passed': passed,
        'failed': failed,
        'pass_rate':
            total > 0 ? '${(passed / total * 100).toStringAsFixed(1)}%' : '–',
      },
      'sessions': sessions.map((s) => s.toJson()).toList(),
    });
  }

  String _toText(List<TestSession> sessions) {
    final buf = StringBuffer()
      ..writeln('PulseOps Test Report — ${DateTime.now().toIso8601String()}')
      ..writeln('-' * 60);

    final passed = sessions.where((s) => s.isPassed).length;
    final failed = sessions.where((s) => s.isFailed).length;
    final total = sessions.length;
    final passRate = total > 0
        ? ' (${(passed / total * 100).toStringAsFixed(0)}% pass rate)'
        : '';
    buf
      ..writeln('Total: $total  Passed: $passed  Failed: $failed$passRate')
      ..writeln('=' * 60);

    for (final s in sessions) {
      final icon = s.isPassed
          ? '[PASS]'
          : s.isFailed
              ? '[FAIL]'
              : s.isRunning
                  ? '[RUN] '
                  : '[SKIP]';
      buf
        ..writeln()
        ..writeln('$icon  ${s.name}  (${s.duration.inMilliseconds} ms)');
      if (s.group != null) buf.writeln('       Group: ${s.group}');
      if (s.failureMessage != null) {
        buf.writeln('       Failure: ${s.failureMessage}');
      }
      if (s.events.isNotEmpty) {
        buf.writeln('       Events:');
        for (final e in s.events) {
          final lvl = '[${e.level.name.toUpperCase().padRight(7)}]';
          final dur =
              e.duration != null ? ' (${e.duration!.inMilliseconds} ms)' : '';
          buf.writeln('         $lvl ${e.message}$dur');
        }
      }
      if (s.networkRequests.isNotEmpty) {
        buf.writeln('       Network:');
        for (final r in s.networkRequests) {
          buf.writeln(
            '         ${r.method.padRight(6)} ${r.endpoint}'
            ' → ${r.statusCode ?? r.status.name}'
            ' (${r.duration.inMilliseconds} ms)',
          );
        }
      }
      if (s.stackTrace != null) {
        buf.writeln('       Stack trace:');
        final lines = s.stackTrace!.split('\n').take(8);
        for (final l in lines) {
          buf.writeln('         $l');
        }
      }
      buf.writeln('-' * 60);
    }
    return buf.toString().trimRight();
  }
}
