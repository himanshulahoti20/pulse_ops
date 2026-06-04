/// Lifecycle record for a single Flutter object tracked via
/// [MemoryAllocations].
class TrackedObject {
  TrackedObject({
    required this.token,
    required this.type,
    required this.createdAt,
    this.library,
  });

  final String token;
  final String type;

  /// The library that declared the type, when available.
  final String? library;

  final DateTime createdAt;
  bool disposed = false;
  DateTime? disposedAt;

  Duration get age => (disposedAt ?? DateTime.now()).difference(createdAt);

  /// Objects not disposed within this many seconds after creation are
  /// considered a potential leak.
  static const leakThresholdSeconds = 30;

  bool get isPotentialLeak =>
      !disposed &&
      DateTime.now().difference(createdAt).inSeconds > leakThresholdSeconds;
}
