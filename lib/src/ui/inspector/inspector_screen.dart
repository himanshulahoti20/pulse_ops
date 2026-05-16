import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../network/models/network_record.dart';
import '../../network/utils/log_exporter.dart';
import '../../providers/providers.dart';
import '../theme/pulse_theme.dart';
import 'request_details_screen.dart';
import 'widgets/empty_state.dart';
import 'widgets/request_tile.dart';

class InspectorScreen extends ConsumerStatefulWidget {
  const InspectorScreen({
    super.key,
    this.retryDio,
    this.scrollController,
  });

  final Dio? retryDio;

  /// When the inspector is hosted inside a [DraggableScrollableSheet] this
  /// controller is forwarded to the list view so drag gestures continue to
  /// resize the sheet once the list reaches its scroll bounds.
  final ScrollController? scrollController;

  @override
  ConsumerState<InspectorScreen> createState() => _InspectorScreenState();
}

class _InspectorScreenState extends ConsumerState<InspectorScreen> {
  final _searchController = TextEditingController();
  static const _exporter = NetworkLogExporter();

  static const _methods = <String>['GET', 'POST', 'PUT', 'PATCH', 'DELETE'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(filteredRecordsProvider);
    final filter = ref.watch(inspectorFilterProvider);
    final allRecords = ref.watch(networkRecordsProvider).maybeWhen(
          data: (r) => r,
          orElse: () => const <NetworkRecord>[],
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('PulseOps'),
        actions: [
          IconButton(
            tooltip: 'Export logs',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: allRecords.isEmpty
                ? null
                : () => _openExportSheet(context, allRecords),
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () {
              ref.read(networkStoreProvider).clear();
            },
          ),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                color: PulseTheme.textPrimary,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: 'Search by URL, method, status…',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: PulseTheme.textSecondary, size: 20),
                suffixIcon: filter.search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(inspectorFilterProvider.notifier).update(
                                (s) => s.copyWith(search: ''),
                              );
                        },
                      ),
              ),
              onChanged: (v) => ref
                  .read(inspectorFilterProvider.notifier)
                  .update((s) => s.copyWith(search: v)),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'Failed',
                  selected: filter.failedOnly,
                  onTap: () => ref
                      .read(inspectorFilterProvider.notifier)
                      .update((s) => s.copyWith(failedOnly: !s.failedOnly)),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: PulseTheme.border,
                ),
                const SizedBox(width: 8),
                for (final m in _methods) ...[
                  _FilterChip(
                    label: m,
                    selected: filter.method == m,
                    onTap: () =>
                        ref.read(inspectorFilterProvider.notifier).update((s) {
                      if (s.method == m) {
                        return s.copyWith(clearMethod: true);
                      }
                      return s.copyWith(method: m);
                    }),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: records.isEmpty
                ? const EmptyState(
                    title: 'No requests yet',
                    subtitle:
                        'PulseOps is listening. Fire a request from your app to see it here in real time.',
                  )
                : ListView.separated(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final r = records[index];
                      return RequestTile(
                        record: r,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => RequestDetailsScreen(
                                recordId: r.id,
                                retryDio: widget.retryDio,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExportSheet(
    BuildContext context,
    List<NetworkRecord> records,
  ) async {
    final selected = await showModalBottomSheet<LogExportFormat>(
      context: context,
      backgroundColor: PulseTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Export logs',
                    style: TextStyle(
                      color: PulseTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              _ExportTile(
                icon: Icons.data_object_rounded,
                title: 'JSON',
                subtitle: 'Structured payload, ideal for tooling.',
                onTap: () =>
                    Navigator.of(sheetContext).pop(LogExportFormat.json),
              ),
              _ExportTile(
                icon: Icons.notes_rounded,
                title: 'Plain text',
                subtitle: 'Readable summary per request.',
                onTap: () =>
                    Navigator.of(sheetContext).pop(LogExportFormat.text),
              ),
              _ExportTile(
                icon: Icons.terminal_rounded,
                title: 'cURL commands',
                subtitle: 'Replay every captured request.',
                onTap: () =>
                    Navigator.of(sheetContext).pop(LogExportFormat.curl),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    final payload = _exporter.export(records, format: selected);
    await _shareOrCopy(payload, selected);
  }

  Future<void> _shareOrCopy(String payload, LogExportFormat format) async {
    final ext = switch (format) {
      LogExportFormat.json => 'json',
      LogExportFormat.text => 'txt',
      LogExportFormat.curl => 'sh',
    };
    final filename =
        'pulse-ops-${DateTime.now().millisecondsSinceEpoch}.$ext';
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(payload.codeUnits),
              name: filename,
              mimeType: format == LogExportFormat.json
                  ? 'application/json'
                  : 'text/plain',
            ),
          ],
          fileNameOverrides: [filename],
        ),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: payload));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logs copied to clipboard')),
      );
    }
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: PulseTheme.accent),
      title: Text(
        title,
        style: const TextStyle(
          color: PulseTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: PulseTheme.textSecondary, fontSize: 12),
      ),
      onTap: onTap,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? PulseTheme.accent : PulseTheme.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? PulseTheme.accent.withValues(alpha: 0.14)
                : PulseTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? PulseTheme.accent.withValues(alpha: 0.5)
                  : PulseTheme.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.4,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}
