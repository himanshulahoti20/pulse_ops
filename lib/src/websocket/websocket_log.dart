import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import '../network/utils/sanitizer.dart';

enum WebSocketDirection { sent, received }

class WebSocketMessage {
  WebSocketMessage(this.direction, this.data, this.sizeBytes)
      : at = DateTime.now();

  final WebSocketDirection direction;

  /// Decoded JSON (sanitized) when the payload was JSON text, otherwise the
  /// raw text, or a `<binary N bytes>` placeholder.
  final Object? data;
  final int sizeBytes;
  final DateTime at;
}

/// One logged WebSocket connection. Obtain via [WebSocketLogStore.open].
class WebSocketSession {
  WebSocketSession._(this._store, this.id, this.url, this.maxMessages)
      : openedAt = DateTime.now();

  final WebSocketLogStore _store;
  final String id;
  final String url;
  final int maxMessages;
  final DateTime openedAt;

  final Queue<WebSocketMessage> _messages = Queue<WebSocketMessage>();
  DateTime? closedAt;
  int? closeCode;
  String? closeReason;
  String? error;

  /// Messages, newest first.
  List<WebSocketMessage> get messages => List.unmodifiable(_messages);
  bool get isOpen => closedAt == null;
  int get sentCount => _count(WebSocketDirection.sent);
  int get receivedCount => _count(WebSocketDirection.received);

  int _count(WebSocketDirection d) =>
      _messages.where((m) => m.direction == d).length;

  void sent(Object? data) => _add(WebSocketDirection.sent, data);
  void received(Object? data) => _add(WebSocketDirection.received, data);

  void failed(Object err) {
    error = err.toString();
    _store._emit();
  }

  void close({int? code, String? reason}) {
    if (!isOpen) return;
    closedAt = DateTime.now();
    closeCode = code;
    closeReason = reason;
    _store._emit();
  }

  /// Logs every event of [source] (e.g. `channel.stream`) as received and
  /// marks the session closed when it completes. Events pass through
  /// unchanged.
  Stream<T> trackIncoming<T>(Stream<T> source) =>
      source.transform(StreamTransformer<T, T>.fromHandlers(
        handleData: (data, sink) {
          received(data);
          sink.add(data);
        },
        handleError: (e, st, sink) {
          failed(e);
          sink.addError(e, st);
        },
        handleDone: (sink) {
          close();
          sink.close();
        },
      ));

  void _add(WebSocketDirection d, Object? raw) {
    final (data, size) = _store._describe(raw);
    _messages.addFirst(WebSocketMessage(d, data, size));
    if (_messages.length > maxMessages) _messages.removeLast();
    _store._emit();
  }
}

/// Ring-buffer of logged WebSocket connections, shown in the inspector.
///
/// ```dart
/// final session = PulseOps.instance.webSocketLog.open(url);
/// final channel = WebSocketChannel.connect(Uri.parse(url));
/// channel.stream... // use session.trackIncoming(channel.stream)
/// session.sent(message); channel.sink.add(message);
/// ```
class WebSocketLogStore {
  WebSocketLogStore({
    this.maxSessions = 20,
    this.maxMessagesPerSession = 200,
    Sanitizer? sanitizer,
  }) : _sanitizer = sanitizer;

  final int maxSessions;
  final int maxMessagesPerSession;
  final Sanitizer? _sanitizer;

  final Queue<WebSocketSession> _sessions = Queue<WebSocketSession>();
  final _controller =
      StreamController<List<WebSocketSession>>.broadcast(sync: false);
  int _counter = 0;

  /// Sessions, newest first.
  List<WebSocketSession> get sessions => List.unmodifiable(_sessions);

  /// Emits the current list first, then every change.
  Stream<List<WebSocketSession>> get stream async* {
    yield sessions;
    yield* _controller.stream;
  }

  WebSocketSession open(String url) {
    final session = WebSocketSession._(
      this,
      '${DateTime.now().microsecondsSinceEpoch}_${_counter++}',
      url,
      maxMessagesPerSession,
    );
    _sessions.addFirst(session);
    if (_sessions.length > maxSessions) _sessions.removeLast();
    _emit();
    return session;
  }

  void clear() {
    _sessions.clear();
    _emit();
  }

  void dispose() => _controller.close();

  (Object?, int) _describe(Object? raw) {
    if (raw is String) {
      Object? decoded = raw;
      try {
        // Only structured JSON is decoded; "123" or "true" stay text.
        final j = jsonDecode(raw);
        if (j is Map || j is List) decoded = j;
      } catch (_) {}
      return (
        _sanitizer?.sanitizeBody(decoded) ?? decoded,
        utf8.encode(raw).length
      );
    }
    if (raw is List<int>) return ('<binary ${raw.length} bytes>', raw.length);
    return (raw?.toString(), 0);
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(sessions);
  }
}
