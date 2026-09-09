import 'dart:convert';

import 'package:flutter/material.dart';

import '../i18n.dart';
import '../models.dart';
import '../theme/app_theme.dart';
import 'tool_icon.dart';

/// Recreates ToolPartView.svelte: a uniform tool-result card with three
/// independent collapsible sections — input params, content (the tool output)
/// and metadata (change id, diff, +/- additions/deletions). Every tool uses the
/// same layout so cards are consistent regardless of tool family.
///
/// The standalone agent exposes no change-diff / build-task surfaces, so the
/// change id and diff are rendered as plain collapsible text (no navigation).
class ToolPartView extends StatefulWidget {
  final ChatPart part;
  final bool isStreaming;
  const ToolPartView({
    super.key,
    required this.part,
    this.isStreaming = false,
  });

  @override
  State<ToolPartView> createState() => _ToolPartViewState();
}

class _ToolPartViewState extends State<ToolPartView> {
  // Card-level fold + per-section folds (input / content / metadata).
  bool _open = true;
  bool _inputOpen = true;
  bool _contentOpen = true;
  bool _metaOpen = true;

  ChatPart get part => widget.part;
  ToolState? get state => part.state;
  String get tool => part.tool;
  String get status => state?.status ?? 'complete';
  Map<String, dynamic> get input => state?.input ?? const <String, dynamic>{};

  bool get hasError => status == 'error';
  bool get _running => widget.isStreaming && status == 'running';

  String? get _changeId {
    final c = state?.changeId;
    return (c is String && c.isNotEmpty) ? c : null;
  }

  String? get _diff {
    final d = state?.diff;
    return (d is String && d.isNotEmpty) ? d : null;
  }

  bool get _hasMeta =>
      _changeId != null ||
      _diff != null ||
      (state?.additions != null && state!.additions! > 0) ||
      (state?.deletions != null && state!.deletions! > 0) ||
      (state?.error != null && (state!.error ?? '').isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final dotColor = hasError
        ? colors.destructive
        : _running
            ? colors.warning
            : colors.success;

    return Container(
      decoration: BoxDecoration(
        color: hasError
            ? colors.destructive.withValues(alpha: 0.05)
            : colors.muted.withValues(alpha: 0.35),
        borderRadius: AppRadius.rSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    hasError
                        ? Icons.error_rounded
                        : _running
                            ? Icons.more_horiz_rounded
                            : Icons.check_circle_rounded,
                    size: 14,
                    color: dotColor,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ToolIcon(tool),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(toolDisplayName(tool),
                        overflow: TextOverflow.ellipsis,
                        style: text.meta.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.mutedForeground)),
                  ),
                  if ((state?.title ?? '').isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(state!.title!,
                          overflow: TextOverflow.ellipsis,
                          style: text.micro.copyWith(
                              color: colors.mutedForeground,
                              fontStyle: FontStyle.italic)),
                    ),
                  ],
                  Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 14,
                    color: colors.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...[
            if (input.isNotEmpty)
              _Section(
                title: context.l10n.toolInputParams,
                icon: Icons.data_object_rounded,
                open: _inputOpen,
                onToggle: () => setState(() => _inputOpen = !_inputOpen),
                child: _MonoText(_prettyJson(input)),
              ),
            if (hasError)
              _Section(
                title: context.l10n.error,
                icon: Icons.error_outline_rounded,
                open: true,
                onToggle: () {},
                destructive: true,
                child: _MonoText(state!.error ?? '', destructive: true),
              ),
            _Section(
              title: context.l10n.content,
              icon: Icons.description_outlined,
              open: _contentOpen,
              onToggle: () => setState(() => _contentOpen = !_contentOpen),
              child: _running
                  ? Text(context.l10n.running,
                      style: text.micro.copyWith(
                          color: colors.mutedForeground,
                          fontStyle: FontStyle.italic))
                  : _MonoText(state?.output ?? ''),
            ),
            if (_hasMeta)
              _Section(
                title: context.l10n.metadata,
                icon: Icons.info_outline_rounded,
                open: _metaOpen,
                onToggle: () => setState(() => _metaOpen = !_metaOpen),
                child: _MetaBody(
                  changeId: _changeId,
                  diff: _diff,
                  additions: state?.additions,
                  deletions: state?.deletions,
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _prettyJson(Map<String, dynamic> m) {
    try {
      return const JsonEncoder.withIndent('  ').convert(m);
    } catch (_) {
      return m.toString();
    }
  }
}

/// A collapsible labelled section inside a tool card.
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool open;
  final VoidCallback? onToggle;
  final Widget child;
  final bool destructive;
  const _Section({
    required this.title,
    required this.icon,
    required this.open,
    required this.onToggle,
    required this.child,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.5),
        border: Border.all(
            color: destructive
                ? colors.destructive.withValues(alpha: 0.4)
                : colors.border.withValues(alpha: 0.5)),
        borderRadius: AppRadius.rSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.sm)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    open
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    size: 14,
                    color: colors.mutedForeground,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(icon,
                      size: 13,
                      color: destructive
                          ? colors.destructive
                          : colors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(title,
                      style: text.micro.copyWith(
                          color: destructive
                              ? colors.destructive
                              : colors.mutedForeground)),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
              child: child,
            ),
        ],
      ),
    );
  }
}

/// Selectable mono text with scroll for the input / content / metadata body.
class _MonoText extends StatelessWidget {
  final String text;
  final bool destructive;
  const _MonoText(this.text, {this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final colors2 = textOf(context);
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 220),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: SingleChildScrollView(
        child: SelectableText(text,
            style: colors2.mono.copyWith(
                fontSize: 11,
                color: destructive ? colors.destructive : colors.foreground)),
      ),
    );
  }
}

/// Metadata body: change id, diff, +/- additions/deletions as plain text.
class _MetaBody extends StatelessWidget {
  final String? changeId;
  final String? diff;
  final int? additions;
  final int? deletions;
  const _MetaBody({
    this.changeId,
    this.diff,
    this.additions,
    this.deletions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final rows = <Widget>[];
    if (changeId != null) {
      rows.add(_Row(
        icon: Icons.commit_rounded,
        label: 'change_id',
        value: changeId!,
        color: colors.primary,
      ));
    }
    if ((additions != null && additions! > 0) ||
        (deletions != null && deletions! > 0)) {
      rows.add(_Row(
        icon: Icons.difference_rounded,
        label: 'diff',
        value: '+${additions ?? 0} -${deletions ?? 0}',
        color: (deletions ?? 0) > 0 ? colors.destructive : colors.success,
      ));
    }
    if (diff != null && diff!.isNotEmpty) {
      rows.add(Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.xs),
        constraints: const BoxConstraints(maxHeight: 220),
        decoration: BoxDecoration(
          color: colors.muted.withValues(alpha: 0.4),
          borderRadius: AppRadius.rSm,
        ),
        child: SingleChildScrollView(
          child: SelectableText(diff!,
              style: text.mono.copyWith(fontSize: 11)),
        ),
      ));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(label,
              style: text.micro.copyWith(color: colors.mutedForeground)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(value,
                overflow: TextOverflow.ellipsis,
                style: text.mono.copyWith(fontSize: 11, color: color)),
          ),
        ],
      ),
    );
  }
}
