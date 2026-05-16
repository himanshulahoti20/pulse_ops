import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/models/network_record.dart';
import '../../network/utils/sanitizer.dart';
import '../../providers/providers.dart';
import '../theme/pulse_theme.dart';
import 'tabs/curl_tab.dart';
import 'tabs/headers_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/request_tab.dart';
import 'tabs/response_tab.dart';
import 'widgets/method_chip.dart';

class RequestDetailsScreen extends ConsumerWidget {
  const RequestDetailsScreen({
    super.key,
    required this.recordId,
    this.retryDio,
  });

  final String recordId;
  final Dio? retryDio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(networkRecordsProvider).maybeWhen(
          data: (rs) => rs,
          orElse: () => const <NetworkRecord>[],
        );
    NetworkRecord? record;
    for (final r in records) {
      if (r.id == recordId) {
        record = r;
        break;
      }
    }

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request')),
        body: const Center(
          child: Text(
            'This request was evicted from the buffer.',
            style: TextStyle(color: PulseTheme.textSecondary),
          ),
        ),
      );
    }

    final r = record;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              MethodChip(method: r.method),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.endpoint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Copy URL',
              icon: const Icon(Icons.link_rounded),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: r.url));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URL copied')),
                  );
                }
              },
            ),
            if (retryDio != null)
              IconButton(
                tooltip: 'Retry',
                icon: const Icon(Icons.replay_rounded),
                onPressed: () => _retry(context, r),
              ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Headers'),
              Tab(text: 'Request'),
              Tab(text: 'Response'),
              Tab(text: 'cURL'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OverviewTab(record: r),
            HeadersTab(
              request: r.requestHeaders,
              response: r.responseHeaders,
            ),
            RequestTab(record: r),
            ResponseTab(record: r),
            CurlTab(record: r),
          ],
        ),
      ),
    );
  }

  Future<void> _retry(BuildContext context, NetworkRecord record) async {
    final dio = retryDio;
    if (dio == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text('Retrying ${record.method} ${record.endpoint}…')),
    );
    try {
      await dio.request<dynamic>(
        record.url,
        data: _retryBody(record),
        queryParameters: record.queryParameters,
        options: Options(
          method: record.method,
          headers: _nonRedactedHeaders(record),
        ),
      );
    } catch (_) {
      // Already captured by the interceptor; nothing else to do.
    }
  }

  Object? _retryBody(NetworkRecord r) {
    if (r.isMultipart) return null;
    final body = r.requestBody;
    if (body is String || body is Map || body is List) return body;
    return null;
  }

  Map<String, dynamic>? _nonRedactedHeaders(NetworkRecord r) {
    if (r.requestHeaders.isEmpty) return null;
    return {
      for (final e in r.requestHeaders.entries)
        if (e.value != Sanitizer.redactedPlaceholder) e.key: e.value,
    };
  }
}
