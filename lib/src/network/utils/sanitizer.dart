/// Redacts sensitive values out of headers, query params, and JSON-shaped
/// request/response bodies before they are displayed in the inspector or
/// forwarded to a crash reporter.
class Sanitizer {
  Sanitizer(List<String> keys)
      : _lowered = keys.map((k) => k.toLowerCase()).toSet();

  final Set<String> _lowered;

  static const String redactedPlaceholder = '••• REDACTED •••';

  /// Returns a copy of [headers] with any sensitive values redacted.
  Map<String, dynamic> sanitizeHeaders(Map<String, dynamic>? headers) {
    if (headers == null) return const <String, dynamic>{};
    final out = <String, dynamic>{};
    headers.forEach((key, value) {
      if (_isSensitive(key)) {
        out[key] = redactedPlaceholder;
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  /// Walks an arbitrary JSON-ish structure and redacts any matching keys.
  Object? sanitizeBody(Object? body) {
    if (body == null) return null;
    return _walk(body);
  }

  Object? _walk(Object? value) {
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((key, v) {
        final keyStr = key.toString();
        if (_isSensitive(keyStr)) {
          out[keyStr] = redactedPlaceholder;
        } else {
          out[keyStr] = _walk(v);
        }
      });
      return out;
    }
    if (value is List) {
      return value.map(_walk).toList();
    }
    return value;
  }

  bool _isSensitive(String key) => _lowered.contains(key.toLowerCase());
}
