/// Simulated network conditions applied by [PulseDioInterceptor].
///
/// Only requests made through the PulseOps interceptor are affected; the
/// delay is added on top of the real round-trip.
enum NetworkThrottle {
  none('No throttling', 0, 0),
  lte('LTE', 50, 12000000),
  fast3g('Fast 3G', 150, 1600000),
  slow3g('Slow 3G', 400, 400000),
  offline('Offline', 0, 0);

  const NetworkThrottle(this.label, this.latencyMs, this.bitsPerSecond);

  final String label;

  /// Fixed delay added before each request is sent.
  final int latencyMs;

  /// Simulated bandwidth; `0` means unlimited.
  final int bitsPerSecond;

  /// Time to push [bytes] through the simulated link.
  Duration transferTime(int? bytes) {
    if (bitsPerSecond == 0 || bytes == null || bytes <= 0) return Duration.zero;
    final ms = (bytes * 8000 / bitsPerSecond).round();
    return Duration(milliseconds: ms > 30000 ? 30000 : ms);
  }
}
