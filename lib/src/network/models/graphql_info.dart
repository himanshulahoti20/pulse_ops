import 'package:flutter/foundation.dart';

/// A GraphQL operation parsed out of a captured request body (or query
/// string for GET requests).
@immutable
class GraphQLInfo {
  const GraphQLInfo({
    required this.type,
    required this.query,
    this.operationName,
    this.variables,
    this.batchSize = 1,
  });

  /// `query`, `mutation` or `subscription`.
  final String type;
  final String? operationName;
  final String query;
  final Object? variables;

  /// Greater than 1 when the request is a batched array of operations; only
  /// the first operation is described.
  final int batchSize;

  /// Short label for list tiles, e.g. `mutation CreatePost`.
  String get label => '$type ${operationName ?? '(anonymous)'}';

  static final _header =
      RegExp(r'^\s*(query|mutation|subscription)\b\s*(\w+)?');

  /// Returns `null` when [body] / [queryParameters] do not look like GraphQL.
  static GraphQLInfo? tryParse(
    Object? body,
    Map<String, dynamic> queryParameters,
  ) {
    var batch = 1;
    Object? candidate = body;
    if (candidate is List && candidate.isNotEmpty) {
      batch = candidate.length;
      candidate = candidate.first;
    }
    if (candidate is! Map) candidate = queryParameters;
    final query = candidate['query'];
    if (query is! String || query.trim().isEmpty) return null;

    final m = _header.firstMatch(query);
    // A bare `{ ... }` selection set is an anonymous query; anything else
    // that is not a GraphQL document (e.g. `?query=shoes`) is rejected.
    if (m == null && !query.trimLeft().startsWith('{')) return null;
    final explicit = candidate['operationName'];
    return GraphQLInfo(
      type: m?.group(1) ?? 'query',
      operationName:
          explicit is String && explicit.isNotEmpty ? explicit : m?.group(2),
      query: query,
      variables: candidate['variables'],
      batchSize: batch,
    );
  }
}
