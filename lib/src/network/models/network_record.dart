import 'package:flutter/foundation.dart';

/// Lifecycle of a captured network call.
enum NetworkStatus {
  pending,
  success,
  error,
  cancelled,
}

/// An immutable snapshot of a single HTTP exchange captured by the
/// PulseOps Dio interceptor.
@immutable
class NetworkRecord {
  const NetworkRecord({
    required this.id,
    required this.method,
    required this.url,
    required this.startedAt,
    this.endedAt,
    this.statusCode,
    this.statusMessage,
    this.requestHeaders = const <String, dynamic>{},
    this.responseHeaders = const <String, dynamic>{},
    this.requestBody,
    this.responseBody,
    this.queryParameters = const <String, dynamic>{},
    this.error,
    this.status = NetworkStatus.pending,
    this.isMultipart = false,
    this.requestSizeBytes,
    this.responseSizeBytes,
  });

  final String id;
  final String method;
  final String url;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? statusCode;
  final String? statusMessage;
  final Map<String, dynamic> requestHeaders;
  final Map<String, dynamic> responseHeaders;
  final Object? requestBody;
  final Object? responseBody;
  final Map<String, dynamic> queryParameters;
  final String? error;
  final NetworkStatus status;
  final bool isMultipart;
  final int? requestSizeBytes;
  final int? responseSizeBytes;

  /// Total round-trip duration. Returns `Duration.zero` for in-flight records.
  Duration get duration {
    final end = endedAt;
    if (end == null) return Duration.zero;
    return end.difference(startedAt);
  }

  /// Convenience: extract the host + path portion of [url].
  String get endpoint {
    try {
      final u = Uri.parse(url);
      final path = u.path.isEmpty ? '/' : u.path;
      return path;
    } catch (_) {
      return url;
    }
  }

  String get host {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return '';
    }
  }

  bool get isSuccess =>
      status == NetworkStatus.success &&
      statusCode != null &&
      statusCode! >= 200 &&
      statusCode! < 300;

  bool get isFailure =>
      status == NetworkStatus.error ||
      (statusCode != null && (statusCode! < 200 || statusCode! >= 400));

  NetworkRecord copyWith({
    String? id,
    String? method,
    String? url,
    DateTime? startedAt,
    DateTime? endedAt,
    int? statusCode,
    String? statusMessage,
    Map<String, dynamic>? requestHeaders,
    Map<String, dynamic>? responseHeaders,
    Object? requestBody,
    Object? responseBody,
    Map<String, dynamic>? queryParameters,
    String? error,
    NetworkStatus? status,
    bool? isMultipart,
    int? requestSizeBytes,
    int? responseSizeBytes,
  }) {
    return NetworkRecord(
      id: id ?? this.id,
      method: method ?? this.method,
      url: url ?? this.url,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      statusCode: statusCode ?? this.statusCode,
      statusMessage: statusMessage ?? this.statusMessage,
      requestHeaders: requestHeaders ?? this.requestHeaders,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      requestBody: requestBody ?? this.requestBody,
      responseBody: responseBody ?? this.responseBody,
      queryParameters: queryParameters ?? this.queryParameters,
      error: error ?? this.error,
      status: status ?? this.status,
      isMultipart: isMultipart ?? this.isMultipart,
      requestSizeBytes: requestSizeBytes ?? this.requestSizeBytes,
      responseSizeBytes: responseSizeBytes ?? this.responseSizeBytes,
    );
  }

  factory NetworkRecord.fromJson(Map<String, dynamic> j) => NetworkRecord(
        id: j['id'] as String,
        method: j['method'] as String,
        url: j['url'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String),
        endedAt: j['endedAt'] != null
            ? DateTime.parse(j['endedAt'] as String)
            : null,
        statusCode: j['statusCode'] as int?,
        statusMessage: j['statusMessage'] as String?,
        requestHeaders:
            (j['requestHeaders'] as Map?)?.cast<String, dynamic>() ?? {},
        responseHeaders:
            (j['responseHeaders'] as Map?)?.cast<String, dynamic>() ?? {},
        requestBody: j['requestBody'],
        responseBody: j['responseBody'],
        queryParameters:
            (j['queryParameters'] as Map?)?.cast<String, dynamic>() ?? {},
        error: j['error'] as String?,
        status: NetworkStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => NetworkStatus.pending,
        ),
        isMultipart: j['isMultipart'] as bool? ?? false,
        requestSizeBytes: j['requestSizeBytes'] as int?,
        responseSizeBytes: j['responseSizeBytes'] as int?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'method': method,
        'url': url,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'statusCode': statusCode,
        'statusMessage': statusMessage,
        'requestHeaders': requestHeaders,
        'responseHeaders': responseHeaders,
        'requestBody': _jsonSafe(requestBody),
        'responseBody': _jsonSafe(responseBody),
        'queryParameters': queryParameters,
        'error': error,
        'status': status.name,
        'isMultipart': isMultipart,
        'requestSizeBytes': requestSizeBytes,
        'responseSizeBytes': responseSizeBytes,
      };

  static Object? _jsonSafe(Object? v) {
    if (v == null || v is String || v is num || v is bool) return v;
    if (v is Map || v is List) return v;
    return v.toString();
  }

  Map<String, dynamic> toSummaryMap() => <String, dynamic>{
        'id': id,
        'method': method,
        'url': url,
        'status': statusCode,
        'duration_ms': duration.inMilliseconds,
        'started_at': startedAt.toIso8601String(),
        'result': status.name,
        if (error != null) 'error': error,
      };
}
