import 'dart:convert';

import '../models/network_record.dart';
import 'curl_builder.dart';

/// Output format for [NetworkLogExporter.export].
enum LogExportFormat {
  /// Pretty-printed JSON array of full record payloads.
  json,

  /// Human-readable text — one block per request with method, URL, status,
  /// duration, headers, and bodies.
  text,

  /// One `curl` command per record, separated by blank lines.
  curl,
}

/// Serializes captured [NetworkRecord]s into shareable strings.
///
/// The exporter relies on the same fields already shown in the inspector, so
/// sanitization that ran in the interceptor is preserved verbatim. Records
/// are emitted in chronological order (oldest first) regardless of the
/// store's iteration order.
class NetworkLogExporter {
  const NetworkLogExporter({CurlBuilder curlBuilder = const CurlBuilder()})
      : _curl = curlBuilder;

  final CurlBuilder _curl;

  String export(
    Iterable<NetworkRecord> records, {
    LogExportFormat format = LogExportFormat.json,
  }) {
    final ordered = records.toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    switch (format) {
      case LogExportFormat.json:
        return const JsonEncoder.withIndent('  ').convert(
          ordered.map(_toMap).toList(),
        );
      case LogExportFormat.text:
        return ordered.map(_toText).join('\n\n${'-' * 60}\n\n');
      case LogExportFormat.curl:
        return ordered.map(_curl.build).join('\n\n');
    }
  }

  Map<String, dynamic> _toMap(NetworkRecord r) => <String, dynamic>{
        'id': r.id,
        'method': r.method,
        'url': r.url,
        'status_code': r.statusCode,
        'status_message': r.statusMessage,
        'result': r.status.name,
        'started_at': r.startedAt.toIso8601String(),
        'ended_at': r.endedAt?.toIso8601String(),
        'duration_ms': r.duration.inMilliseconds,
        'is_multipart': r.isMultipart,
        'request_size_bytes': r.requestSizeBytes,
        'response_size_bytes': r.responseSizeBytes,
        'query_parameters': r.queryParameters,
        'request_headers': r.requestHeaders,
        'response_headers': r.responseHeaders,
        'request_body': r.requestBody,
        'response_body': r.responseBody,
        if (r.error != null) 'error': r.error,
      };

  String _toText(NetworkRecord r) {
    final buf = StringBuffer()
      ..writeln('${r.method.toUpperCase()} ${r.url}')
      ..writeln('Result: ${r.status.name}'
          '${r.statusCode != null ? ' (${r.statusCode})' : ''}')
      ..writeln('Started: ${r.startedAt.toIso8601String()}')
      ..writeln('Duration: ${r.duration.inMilliseconds} ms');
    if (r.requestHeaders.isNotEmpty) {
      buf
        ..writeln('Request headers:')
        ..writeln(_indentMap(r.requestHeaders));
    }
    if (r.requestBody != null) {
      buf
        ..writeln('Request body:')
        ..writeln(_indent(_stringify(r.requestBody)));
    }
    if (r.responseHeaders.isNotEmpty) {
      buf
        ..writeln('Response headers:')
        ..writeln(_indentMap(r.responseHeaders));
    }
    if (r.responseBody != null) {
      buf
        ..writeln('Response body:')
        ..writeln(_indent(_stringify(r.responseBody)));
    }
    if (r.error != null) {
      buf.writeln('Error: ${r.error}');
    }
    return buf.toString().trimRight();
  }

  String _indentMap(Map<String, dynamic> map) =>
      map.entries.map((e) => '  ${e.key}: ${e.value}').join('\n');

  String _indent(String value) =>
      value.split('\n').map((l) => '  $l').join('\n');

  String _stringify(Object? value) {
    if (value == null) return 'null';
    if (value is String) return value;
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}
