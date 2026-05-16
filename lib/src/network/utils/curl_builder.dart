import 'dart:convert';

import '../models/network_record.dart';

/// Generates an executable `curl` command for a captured [NetworkRecord].
class CurlBuilder {
  const CurlBuilder();

  String build(NetworkRecord r) {
    final parts = <String>['curl'];

    if (r.method.toUpperCase() != 'GET') {
      parts.add('-X ${r.method.toUpperCase()}');
    }

    r.requestHeaders.forEach((key, value) {
      final escaped = _shellEscape('$key: $value');
      parts.add('-H $escaped');
    });

    final body = r.requestBody;
    if (body != null && _hasBody(r.method)) {
      final encoded = _encodeBody(body);
      if (encoded.isNotEmpty) {
        parts.add('--data ${_shellEscape(encoded)}');
      }
    }

    parts.add(_shellEscape(_fullUrl(r)));

    return parts.join(' \\\n  ');
  }

  String _fullUrl(NetworkRecord r) {
    if (r.queryParameters.isEmpty) return r.url;
    try {
      final uri = Uri.parse(r.url);
      if (uri.hasQuery) return r.url;
      final merged =
          uri.replace(queryParameters: r.queryParameters.map(
        (k, v) => MapEntry(k, v?.toString() ?? ''),
      ));
      return merged.toString();
    } catch (_) {
      return r.url;
    }
  }

  bool _hasBody(String method) {
    final m = method.toUpperCase();
    return m == 'POST' || m == 'PUT' || m == 'PATCH' || m == 'DELETE';
  }

  String _encodeBody(Object body) {
    if (body is String) return body;
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }

  String _shellEscape(String input) {
    final escaped = input.replaceAll(r"'", r"'\''");
    return "'$escaped'";
  }
}
