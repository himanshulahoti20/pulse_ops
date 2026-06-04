import '../crash/breadcrumb.dart';
import '../network/models/network_record.dart';

/// A sink that receives every crash and every failed network request captured
/// by PulseOps so the host app can forward them to its own analytics or
/// logging backend.
///
/// Implement this interface and pass it to [PulseOps.initialize] via
/// `eventExporter:` to start receiving events.
///
/// ```dart
/// class MyExporter implements PulseEventExporter {
///   @override
///   Future<void> onFailedRequest(NetworkRecord r) async {
///     await MyAnalytics.track('api_error', {
///       'url': r.url, 'status': r.statusCode, 'error': r.error,
///     });
///   }
///
///   @override
///   Future<void> onCrash(Object error, StackTrace? st, {
///     required String? reason,
///     required bool fatal,
///     required List<Breadcrumb> breadcrumbs,
///     required List<NetworkRecord> recentRequests,
///   }) async {
///     await MyAnalytics.trackCrash(error.toString(), fatal: fatal);
///   }
/// }
/// ```
abstract class PulseEventExporter {
  /// Called for every network request that completes with an error status
  /// (non-2xx response, timeout, connection failure, etc.).
  Future<void> onFailedRequest(NetworkRecord record);

  /// Called whenever an error is reported through PulseOps — both automatic
  /// uncaught errors and explicit [PulseOps.recordError] calls.
  Future<void> onCrash(
    Object error,
    StackTrace? stackTrace, {
    required String? reason,
    required bool fatal,
    required List<Breadcrumb> breadcrumbs,
    required List<NetworkRecord> recentRequests,
  });
}
