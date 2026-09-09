import 'package:flutter/material.dart';

import '../i18n.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import 'tool_icon.dart';

/// Recreates ToolPartView.svelte + family-agnostic body rendering.
///
/// A tool result is drawn with a shared header (status dot, icon, name, fold
/// arrow) and a text body (the tool's output). The standalone agent exposes no
/// change-diff / build-task surfaces, so we render the raw output only.
class ToolPartView extends StatefulWidget {
  final ChatPart part;
  final bool isStreaming;
  final void Function(String changeId)? onOpenChange;
  const ToolPartView({
    super.key,
    required this.part,
    this.isStreaming = false,
    this.onOpenChange,
  });

  @override
  State<ToolPartView> createState() => _ToolPartViewState();
}

class _ToolPartViewState extends State<ToolPartView> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final part = widget.part;
    final output = part.text ?? '';
    final name = part.tool ?? 'tool';
    final done = !widget.isStreaming;

    return ClipRRect(
      borderRadius: AppRadius.rSm,
      child: Container(
        color: colors.muted.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    Icon(
                      done
                          ? Icons.check_circle_rounded
                          : Icons.more_horiz_rounded,
                      size: 14,
                      color: done ? colors.success : colors.warning,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ToolIcon(name),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(name,
                          overflow: TextOverflow.ellipsis,
                          style: text.meta.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.mutedForeground)),
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 14,
                      color: colors.mutedForeground,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded && output.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
                child: SelectableText(
                  output,
                  style: text.mono.copyWith(fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
