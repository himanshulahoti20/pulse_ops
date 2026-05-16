import 'dart:async';

import 'package:flutter/foundation.dart';

import '../network/models/network_record.dart';
import 'breadcrumb.dart';

/// Abstract bridge to a crash reporting backend (e.g. Firebase Crashlytics,
/// Sentry, or a custom logger).
///
/// PulseOps depends only on this interface so the package itself never pulls
/// in `firebase_crashlytics` as a hard dependency. Apps wire up their own
/// implementation — see [FirebaseCrashReporterAdapter] in the README.
abstract class PulseCrashReporter {
  /// Forwarded by the Dio interceptor when an HTTP request fails. Defaults
  /// to a non-fatal record so the app keeps running.
  Future<void> recordNonFatal(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? context,
  });

  /// Forwarded for uncaught fatal errors. The implementation is responsible
  /// for marking the record fatal in whatever backend is in use.
  Future<void> recordFatal(
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  });

  /// Pushed before a crash is recorded so the breadcrumbs accompany the
  /// crash payload. Implementations may translate these into "logs" or
  /// "custom keys" on their backend.
  Future<void> attachBreadcrumbs(List<Breadcrumb> breadcrumbs);

  /// Pushed alongside fatal/non-fatal calls so the most recent API timeline
  /// is preserved for triage.
  Future<void> attachNetworkHistory(List<NetworkRecord> records);

  /// Sets a top-level custom key in the crash backend.
  Future<void> setCustomKey(String key, Object value);
}

/// No-op implementation used when the host app has not configured a crash
/// backend. Errors are routed to `debugPrint` so they are still observable
/// during development.
class NoopCrashReporter implements PulseCrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> recordNonFatal(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? context,
  }) async {
    debugPrint('PulseOps non-fatal: ${reason ?? ''} $error');
  }

  @override
  Future<void> recordFatal(
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    debugPrint('PulseOps fatal: $error');
  }

  @override
  Future<void> attachBreadcrumbs(List<Breadcrumb> breadcrumbs) async {}

  @override
  Future<void> attachNetworkHistory(List<NetworkRecord> records) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}
}
