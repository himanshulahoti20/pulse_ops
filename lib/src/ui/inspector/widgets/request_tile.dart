import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../network/models/network_record.dart';
import '../../theme/pulse_theme.dart';
import 'method_chip.dart';
import 'status_chip.dart';

class RequestTile extends StatelessWidget {
  const RequestTile({
    super.key,
    required this.record,
    required this.onTap,
    this.selected = false,
    this.animate = false,
  });

  final NetworkRecord record;
  final VoidCallback onTap;

  /// Highlights the tile (master-detail layout).
  final bool selected;

  /// Fade + slide in on first build.
  final bool animate;

  static final _timeFmt = DateFormat('HH:mm:ss.SSS');

  @override
  Widget build(BuildContext context) {
    final tile = _build();
    if (!animate) return tile;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child:
            Transform.translate(offset: Offset(0, (1 - t) * 14), child: child),
      ),
      child: tile,
    );
  }

  Widget _build() {
    final gql = record.graphql;
    final compact = PulseTheme.compact.value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding:
              EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 7 : 12),
          decoration: BoxDecoration(
            color: selected ? PulseTheme.surfaceAlt : PulseTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? PulseTheme.accent : PulseTheme.border,
            ),
          ),
          child: Row(
            children: [
              MethodChip(method: record.method),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gql == null
                          ? record.endpoint
                          : '${record.endpoint} · ${gql.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: PulseTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: compact ? 1 : 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            record.host,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: PulseTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 2,
                          width: 2,
                          decoration: BoxDecoration(
                            color: PulseTheme.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeFmt.format(record.startedAt),
                          style: TextStyle(
                            color: PulseTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (record.endedAt != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            height: 2,
                            width: 2,
                            decoration: BoxDecoration(
                              color: PulseTheme.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${record.duration.inMilliseconds}ms',
                            style: TextStyle(
                              color: PulseTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusChip(record: record),
            ],
          ),
        ),
      ),
    );
  }
}
