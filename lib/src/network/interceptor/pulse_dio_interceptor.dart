import 'dart:convert';

import 'package:dio/dio.dart';

import '../../crash/breadcrumb.dart';
import '../../crash/crash_reporter.dart';
import '../../core/pulse_ops_config.dart';
import '../models/network_record.dart';
import '../store/network_store.dart';
import '../utils/sanitizer.dart';

const String _kPulseRequestIdKey = '__pulseops_request_id__';
const String _kPulseStartedAtKey = '__pulseops_started_at__';

/// Dio interceptor that records every request/response into a [NetworkStore]
/// and forwards failures + breadcrumbs into a [PulseCrashReporter].
class PulseDioInterceptor extends Interceptor {
  PulseDioInterceptor({
    required NetworkStore store,
    required PulseOpsConfig config,
    required PulseCrashReporter crashReporter,
    required BreadcrumbTrail breadcrumbs,
    Sanitizer? sanitizer,
  })  : _store = store,
        _config = config,
        _crashReporter = crashReporter,
        _breadcrumbs = breadcrumbs,
        _sanitizer = sanitizer ?? Sanitizer(config.sanitizeKeys);

  final NetworkStore _store;
  final PulseOpsConfig _config;
  final PulseCrashReporter _crashReporter;
  final BreadcrumbTrail _breadcrumbs;
  final Sanitizer _sanitizer;

  int _counter = 0;

  String _nextId() {
    _counter++;
    return '${DateTime.now().microsecondsSinceEpoch}_$_counter';
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final id = _nextId();
    final startedAt = DateTime.now();
    options.extra[_kPulseRequestIdKey] = id;
    options.extra[_kPulseStartedAtKey] = startedAt;

    final isMultipart = options.data is FormData;

    final record = NetworkRecord(
      id: id,
      method: options.method,
      url: options.uri.toString(),
      startedAt: startedAt,
      status: NetworkStatus.pending,
      requestHeaders: _sanitizer.sanitizeHeaders(_stringify(options.headers)),
      queryParameters: Map<String, dynamic>.from(options.queryParameters),
      requestBody: isMultipart
          ? _describeMultipart(options.data as FormData)
          : _sanitizer.sanitizeBody(_normalizeBody(options.data)),
      isMultipart: isMultipart,
      requestSizeBytes: _estimateBytes(options.data),
    );

    _store.add(record);
    _breadcrumbs.log(
      'HTTP ${options.method} ${record.endpoint} — sent',
      data: {'url': record.url},
    );

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _completeRecord(
      options: response.requestOptions,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      responseHeaders: response.headers.map,
      responseBody: response.data,
      error: null,
      status: NetworkStatus.success,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isCancel = err.type == DioExceptionType.cancel;
    final updated = _completeRecord(
      options: err.requestOptions,
      statusCode: err.response?.statusCode,
      statusMessage: err.response?.statusMessage ?? err.message,
      responseHeaders: err.response?.headers.map ?? const {},
      responseBody: err.response?.data,
      error: _describeError(err),
      status: isCancel ? NetworkStatus.cancelled : NetworkStatus.error,
    );

    if (!isCancel &&
        updated != null &&
        _config.captureFailedRequestsAsCrashEvents) {
      _crashReporter.recordNonFatal(
        err,
        stackTrace: err.stackTrace,
        reason: 'PulseOps: HTTP ${updated.method} ${updated.endpoint} failed',
        context: updated.toSummaryMap(),
      );
    }

    handler.next(err);
  }

  NetworkRecord? _completeRecord({
    required RequestOptions options,
    required int? statusCode,
    required String? statusMessage,
    required Map<String, dynamic> responseHeaders,
    required Object? responseBody,
    required String? error,
    required NetworkStatus status,
  }) {
    final id = options.extra[_kPulseRequestIdKey] as String?;
    if (id == null) return null;
    final existing = _store.findById(id);
    if (existing == null) return null;

    final updated = existing.copyWith(
      endedAt: DateTime.now(),
      statusCode: statusCode,
      statusMessage: statusMessage,
      responseHeaders: _sanitizer.sanitizeHeaders(_stringify(responseHeaders)),
      responseBody: _sanitizer.sanitizeBody(_normalizeBody(responseBody)),
      error: error,
      status: status,
      responseSizeBytes: _estimateBytes(responseBody),
    );
    _store.update(updated);

    final tail = status == NetworkStatus.success
        ? '${statusCode ?? '?'} in ${updated.duration.inMilliseconds}ms'
        : 'failed (${statusCode ?? error ?? 'error'})';
    _breadcrumbs.log(
      'HTTP ${updated.method} ${updated.endpoint} — $tail',
      data: updated.toSummaryMap(),
    );
    return updated;
  }

  Map<String, dynamic> _stringify(Map<String, dynamic> input) {
    final out = <String, dynamic>{};
    input.forEach((k, v) {
      if (v is Iterable && v.length == 1) {
        out[k] = v.first;
      } else {
        out[k] = v;
      }
    });
    return out;
  }

  Object? _normalizeBody(Object? body) {
    if (body == null) return null;
    if (body is String) {
      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }
    return body;
  }

  Map<String, dynamic> _describeMultipart(FormData data) {
    return {
      'fields': {for (final f in data.fields) f.key: f.value},
      'files': data.files
          .map((e) => {
                'field': e.key,
                'filename': e.value.filename,
                'length': e.value.length,
                'contentType': e.value.contentType?.toString(),
              })
          .toList(),
    };
  }

  int? _estimateBytes(Object? data) {
    if (data == null) return null;
    if (data is String) return data.length;
    if (data is List<int>) return data.length;
    try {
      return jsonEncode(data).length;
    } catch (_) {
      return null;
    }
  }

  String _describeError(DioException e) {
    final buf = StringBuffer(e.type.name);
    if (e.message != null && e.message!.isNotEmpty) {
      buf.write(': ${e.message}');
    } else if (e.error != null) {
      buf.write(': ${e.error}');
    }
    return buf.toString();
  }
}
