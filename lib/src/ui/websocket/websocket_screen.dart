import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/providers.dart';
import '../../websocket/websocket_log.dart';
import '../inspector/widgets/empty_state.dart';
import '../theme/pulse_scope.dart';
import '../theme/pulse_theme.dart';

/// Lists logged WebSocket connections.
class WebSocketScreen extends ConsumerWidget {
  const WebSocketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(webSocketSessionsProvider).maybeWhen(
          data: (s) => s,
          orElse: () => const <WebSocketSession>[],
        );
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSockets'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: ref.read(webSocketLogProvider).clear,
          ),
        ],
      ),
      body: sessions.isEmpty
          ? const EmptyState(
              title: 'No WebSocket connections',
              subtitle: 'Call PulseOps.instance.webSocketLog.open(url) and log '
                  'messages through the returned session.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = sessions[i];
                final color = s.error != null
                    ? PulseTheme.error
                    : s.isOpen
                        ? PulseTheme.success
                        : PulseTheme.textSecondary;
                return Material(
                  color: PulseTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => pushPulse<void>(
                        context, WebSocketDetailScreen(id: s.id)),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: PulseTheme.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.url,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: PulseTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${s.isOpen ? 'open' : 'closed'} · '
                                  '↑${s.sentCount} ↓${s.receivedCount}',
                                  style: TextStyle(
                                    color: PulseTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Message log of a single WebSocket connection.
class WebSocketDetailScreen extends ConsumerWidget {
  const WebSocketDetailScreen({super.key, required this.id});

  final String id;

  static final _timeFmt = DateFormat('HH:mm:ss.SSS');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(webSocketSessionsProvider).maybeWhen(
          data: (s) => s,
          orElse: () => const <WebSocketSession>[],
        );
    final session = sessions.where((s) => s.id == id).firstOrNull;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('WebSocket')),
        body: Center(
          child: Text(
            'This connection was evicted from the log.',
            style: TextStyle(color: PulseTheme.textSecondary),
          ),
        ),
      );
    }
    final messages = session.messages;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          session.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15),
        ),
      ),
      body: Column(
        children: [
          if (session.error != null || !session.isOpen)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: (session.error != null
                      ? PulseTheme.error
                      : PulseTheme.surfaceAlt)
                  .withValues(alpha: 0.12),
              child: Text(
                [
                  if (session.error != null) 'Error: ${session.error}',
                  if (!session.isOpen)
                    'Closed${session.closeCode != null ? ' (${session.closeCode})' : ''}'
                        '${session.closeReason != null ? ': ${session.closeReason}' : ''}',
                ].join('\n'),
                style: TextStyle(color: PulseTheme.textSecondary, fontSize: 12),
              ),
            ),
          Expanded(
            child: messages.isEmpty
                ? const EmptyState(
                    title: 'No messages yet',
                    subtitle: 'Sent and received frames show up here.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) =>
                        _MessageTile(message: messages[i], fmt: _timeFmt),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message, required this.fmt});

  final WebSocketMessage message;
  final DateFormat fmt;

  @override
  Widget build(BuildContext context) {
    final sent = message.direction == WebSocketDirection.sent;
    final color = sent ? PulseTheme.warning : PulseTheme.success;
    final data = message.data;
    final text = data is String
        ? data
        : const JsonEncoder.withIndent('  ').convert(data);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Message copied')));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PulseTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  sent
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  '${sent ? 'SENT' : 'RECEIVED'} · ${fmt.format(message.at)} · '
                  '${message.sizeBytes} B',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              text,
              maxLines: 12,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: PulseTheme.textPrimary,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
