import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../api.dart';
import '../i18n.dart';
import '../models.dart';
import '../services/download_service.dart';
import '../theme/app_theme.dart';
import 'tool_part.dart';

/// A structured attachment (own `file` part from `/messages` or the send
/// flow). Images render an inline thumbnail (tap to view full) fetched with
/// the auth header; other files render a card that saves to Downloads.
class _FileAttachment extends StatelessWidget {
  final ChatPart part;
  final AgentBindApi api;
  const _FileAttachment({required this.part, required this.api});

  /// Historical attachments were often stored without name/mime/size (only
  /// `code`). Fall back to a HEAD probe of the file to learn its content type,
  /// so images render as thumbnails and files show a sensible name/size.
  Future<({String? mime, int size, String name})> _resolved() async {
    final code = part.code ?? '';
    final probe = await api.fileHead(code);
    return (
      mime: part.mime?.isNotEmpty == true ? part.mime : probe.contentType,
      size: (part.size ?? 0) != 0 ? part.size! : probe.length,
      name: part.name?.isNotEmpty == true ? part.name! : code,
    );
  }

  bool _isImageMime(String? mime) => (mime ?? '').startsWith('image/');

  Future<void> _open(BuildContext context, String mime) async {
    final code = part.code ?? '';
    if (code.isEmpty) return;
    try {
      if (_isImageMime(mime)) {
        final bytes = await api.fetchFileBytes(code);
        if (!context.mounted) return;
        // ignore: use_build_context_synchronously
        showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: InteractiveViewer(
              child: Image.memory(Uint8List.fromList(bytes)),
            ),
          ),
        );
      } else {
        final where = await DownloadService(api).download(
          path: code,
          displayName: part.name ?? code,
          mimeType: mime,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.savedToDownloads(where)),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.sendFailed('$e')),
          duration: const Duration(seconds: 2)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return FutureBuilder<({String? mime, int size, String name})>(
      future: _resolved(),
      builder: (context, snap) {
        final data = snap.data;
        final name = data?.name ?? part.code ?? '';
        final mime = data?.mime;
        final size = data?.size ?? 0;
        final sizeLabel = size > 0 ? _formatBytes(size) : '';
        if (_isImageMime(mime)) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: GestureDetector(
              onTap: () => _open(context, mime ?? ''),
              child: ClipRRect(
                borderRadius: AppRadius.rMd,
                child: SizedBox(
                  width: 220,
                  height: 140,
                  child: _ImageToolImage(code: part.code!, api: api),
                ),
              ),
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 2),
          decoration: BoxDecoration(
            color: colors.muted.withValues(alpha: 0.5),
            borderRadius: AppRadius.rSm,
            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
          ),
          child: InkWell(
            borderRadius: AppRadius.rSm,
            onTap: () => _open(context, mime ?? ''),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.attach_file_rounded,
                    size: 14, color: colors.mutedForeground),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: text.micro.copyWith(color: colors.foreground)),
                ),
                if (sizeLabel.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(sizeLabel,
                      style: text.micro.copyWith(color: colors.mutedForeground)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// An image fetch with the auth header, showing a placeholder while loading.
class _ImageToolImage extends StatelessWidget {  final String code;
  final AgentBindApi api;
  const _ImageToolImage({required this.code, required this.api});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: api.fetchFileBytes(code),
      builder: (context, snap) {
        if (snap.hasData) {
          return Image.memory(Uint8List.fromList(snap.data!),
              fit: BoxFit.cover);
        }
        if (snap.hasError) {
          return const Center(child: Icon(Icons.broken_image_rounded, size: 28));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

/// Pretty-print a byte count (B/KB/MB/GB).
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
}

/// A file chip surfaced from a text part that carries the
/// `[附件 <name> | file:<code> | <mime> | <size>]` reference we embed in the
/// prompt. Clicking it opens an inline image preview (by [code]) or triggers
/// a public-Downloads save for non-image files.
class _FileChip extends StatelessWidget {
  final String code;
  final String label;
  final String? mime;
  final AgentBindApi api;
  const _FileChip({required this.code, required this.label, this.mime, required this.api});

  bool get _isImage => (mime ?? '').startsWith('image/');

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.5),
        borderRadius: AppRadius.rSm,
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        borderRadius: AppRadius.rSm,
        onTap: () => _open(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_isImage ? Icons.image_rounded : Icons.attach_file_rounded,
                size: 14, color: colors.mutedForeground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: text.micro.copyWith(color: colors.foreground)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    try {
      if (_isImage) {
        final bytes = await api.fetchFileBytes(code);
        if (!context.mounted) return;
        // ignore: use_build_context_synchronously
        showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: InteractiveViewer(
              child: Image.memory(Uint8List.fromList(bytes)),
            ),
          ),
        );
      } else {
        // Non-image files save into the public Downloads collection (and
        // show a hop-free snackbar naming the destination).
        final where = await DownloadService(api).download(
          path: code,
          displayName: label,
          mimeType: mime ?? 'application/octet-stream',
        );
        if (!context.mounted) return;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.savedToDownloads(where)),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.sendFailed('$e')),
          duration: const Duration(seconds: 2)));
    }
  }
}

/// Parses embedded `[附件 <name> | file:<code> | <mime> | <size>]` references
/// out of a text part and splits the bubble into inline markdown + file chips.
class _FileRefsText extends StatelessWidget {
  final String text;
  final AgentBindApi api;
  const _FileRefsText({required this.text, required this.api});

  @override
  Widget build(BuildContext context) {
    final parts = _splitFileRefs(text);
    if (parts.isEmpty) return _Markdown(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in parts)
          p is _FileRef
              ? _FileChip(code: p.code, label: p.label, mime: p.mime, api: api)
              : _Markdown(p as String),
      ],
    );
  }
}

class _FileRef {
  final String code;
  final String label;
  final String? mime;
  _FileRef(this.code, this.label, this.mime);
}

final _fileRefRe = RegExp(
  r'\[附件\s+(.+?)\s*\|\s*file:([0-9a-zA-Z]+)\s*\|\s*([^|\]]*)\s*\|\s*([^\]|]*)\]',
);

List<Object> _splitFileRefs(String text) {
  final out = <Object>[];
  var idx = 0;
  for (final m in _fileRefRe.allMatches(text)) {
    if (m.start > idx) out.add(text.substring(idx, m.start));
    out.add(_FileRef(m.group(2)!, m.group(1)!, m.group(3)));
    idx = m.end;
  }
  if (idx < text.length) out.add(text.substring(idx));
  return out;
}

/// Markdown body pre-styled with the shared type scale.
class _Markdown extends StatelessWidget {
  final String data;
  final bool muted;
  const _Markdown(this.data, {this.muted = false});

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: muted
            ? text.meta.copyWith(color: colors.mutedForeground)
            : text.body,
        h1: text.body.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        h2: text.body.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        h3: text.body.copyWith(fontWeight: FontWeight.w600),
        code: text.mono.copyWith(
            color: colors.foreground,
            backgroundColor: colors.muted,
            fontSize: 13),
        codeblockDecoration: BoxDecoration(
          color: colors.muted,
          borderRadius: AppRadius.rSm,
        ),
        blockquote: text.meta.copyWith(color: colors.mutedForeground),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: colors.border, width: 2)),
        ),
        listBullet: text.body,
        tableHead: text.meta.copyWith(fontWeight: FontWeight.w600),
        tableBody: text.meta,
        blockSpacing: AppSpacing.sm,
      ),
    );
  }
}

/// IM-style chat bubble mirroring MessageBubble.svelte. Long-press (mobile)
/// or the hover/overflow affordance exposes copy / undo.
class MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final Future<void> Function(String messageId) onUndo;
  final void Function(String changeId)? onOpenChange;
  final AgentBindApi api;
  final String org;
  final String repo;
  final String branch;
  const MessageBubble({
    super.key,
    required this.msg,
    required this.onUndo,
    required this.api,
    this.onOpenChange,
    this.org = '',
    this.repo = '',
    this.branch = '',
  });

  AgentBindApi get _api => api;

  bool get _hasText =>
      msg.parts.any((p) => p.type == 'text' || p.type == 'reasoning');

  void _copy(BuildContext context) {
    final text = msg.parts
        .where((p) => p.type == 'text' || p.type == 'reasoning')
        .map((p) => p.text)
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.copied), duration: const Duration(seconds: 1)));
  }

  Future<void> _actions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Copy only makes sense for messages with text/reasoning
            // content; pure tool-call messages have nothing to copy.
            if (_hasText)
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: Text(ctx.l10n.copy),
                onTap: () => Navigator.pop(ctx, 'copy'),
              ),
            ListTile(
              leading: const Icon(Icons.undo_rounded),
              title: Text(ctx.l10n.undo),
              onTap: () => Navigator.pop(ctx, 'undo'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'copy':
        _copy(context);
      case 'undo':
        onUndo(msg.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final isUser = msg.role == 'user';
    final isError = msg.role == 'error';
    final isSystem = msg.role == 'system' || msg.role == 'event';
    final isStreaming = msg.status == 'streaming';

    final parts = <Widget>[];
    for (final part in msg.parts) {
      if (part.type == 'text') {
        parts.add(_FileRefsText(text: part.text, api: _api));
      } else if (part.type == 'file') {
        parts.add(_FileAttachment(part: part, api: _api));
      } else if (part.type == 'reasoning') {
        parts.add(_ReasoningBlock(text: part.text, streaming: isStreaming));
      } else if (part.type == 'tool' && part.state != null) {
        parts.add(ToolPartView(
          part: part,
          isStreaming: isStreaming,
        ));
      } else if (part.type == 'compaction') {
        parts.add(_CompactionBlock(text: part.text));
      }
    }
    if (isError) {
      parts.insert(
        0,
        Text(context.l10n.error,
            style: text.micro.copyWith(
                color: colors.destructive, fontWeight: FontWeight.w600)),
      );
    }
    // While the assistant is streaming but NOTHING has arrived yet, show a
    // "thinking…" indicator (it disappears the instant the first part —
    // reasoning, text or a tool call — lands, which is rendered normally).
    if (isStreaming && parts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(context.l10n.thinking,
                style: text.micro.copyWith(color: colors.mutedForeground)),
          ],
        ),
      );
    }

    Widget bubble = Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: isError
            ? colors.destructive.withValues(alpha: 0.10)
            : isSystem
                ? colors.muted.withValues(alpha: 0.30)
                : isUser
                    ? colors.primary.withValues(alpha: 0.12)
                    : colors.card,
        border: Border.all(
          color: isError
              ? colors.destructive.withValues(alpha: 0.4)
              : isSystem
                  ? colors.mutedForeground.withValues(alpha: 0.25)
                  : isUser
                      ? colors.primary.withValues(alpha: 0.4)
                      : colors.border.withValues(alpha: 0.5),
        ),
        borderRadius: AppRadius.rMd,
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < parts.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              parts[i],
            ],
          ]),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: isSystem
            ? CrossAxisAlignment.center
            : isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _actions(context),
            child: bubble,
          ),
          // The actions row shows for EVERY non-streaming message — the
          // agent-ts /undo endpoint accepts any message in the session
          // chain, so tool-call messages are revertible too. Copy is only
          // offered when there is text to copy. System messages show neither
          // (they are not part of the conversation chain).
          if (!isStreaming && !isSystem)
            _BubbleActions(
              isUser: isUser,
              showCopy: _hasText,
              createdAt: msg.createdAt,
              onCopy: () => _copy(context),
              onUndo: () => _undo(context),
            ),
        ],
      ),
    );
  }

  /// Undo asks for confirmation before dispatching the request.
  Future<void> _undo(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.undoTitle),
        content: Text(ctx.l10n.undoBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: colorsOf(ctx).destructive,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.undo),
          ),
        ],
      ),
    );
    if (ok == true) {
      await onUndo(msg.id);
    }
  }
}

class _BubbleActions extends StatelessWidget {
  final bool isUser;
  final bool showCopy;
  final String createdAt;
  final VoidCallback onCopy;
  final VoidCallback onUndo;
  const _BubbleActions({
    required this.isUser,
    required this.showCopy,
    required this.createdAt,
    required this.onCopy,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return Align(
      // User bubbles: actions hug the right edge; assistant: the left edge.
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCopy) ...[
            _tinyIcon(Icons.copy_rounded, context.l10n.copy, onCopy, colors),
            const SizedBox(width: 2),
          ],
          _tinyIcon(Icons.undo_rounded, context.l10n.undo, onUndo, colors),
          if (isUser) ...[
            const SizedBox(width: 4),
            // Show the message's persisted timestamp instead of "you".
            Text(_fmtTime(context, createdAt),
                style: text.micro.copyWith(color: colors.mutedForeground)),
          ],
        ],
      ),
    );
  }

  static String _fmtTime(BuildContext context, String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final d = now.difference(dt);
    final hm =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (d.inMinutes < 1) return context.l10n.timeJustNow;
    if (d.inMinutes < 60) {
      return context.l10n.timeMinAgo('${d.inMinutes}');
    }
    if (d.inHours < 24 && now.day == dt.day) return hm;
    if (d.inHours < 24) return hm;
    return '${dt.month}/${dt.day} $hm';
  }

  // Tight inline action — no App-wide icon-button chrome, no outer padding,
  // so the row sits flush against the bubble side.
  Widget _tinyIcon(IconData icon, String tooltip, VoidCallback onTap,
      AppColors colors) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rSm,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 14, color: colors.mutedForeground),
      ),
    );
  }
}

/// Collapsible reasoning block — matches the web `details` style:
/// amber left border, no Material expansion chrome.
class _ReasoningBlock extends StatelessWidget {
  final String text;
  final bool streaming;
  const _ReasoningBlock({required this.text, required this.streaming});

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text_ = textOf(context);
    return _CollapseBlock(
      label: context.l10n.thinkLabel + (streaming ? '...' : ''),
      labelColor: colors.warning,
      initiallyOpen: true,
      textStyle: text_.micro
          .copyWith(color: colors.warning, fontWeight: FontWeight.w600),
      wrapper: (child) => Container(
        decoration: BoxDecoration(
          color: colors.warning.withValues(alpha: 0.05),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppRadius.sm),
            bottomRight: Radius.circular(AppRadius.sm),
          ),
          border: Border(left: BorderSide(color: colors.warning, width: 2)),
        ),
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.sm, AppSpacing.sm),
        child: child,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: _Markdown(text, muted: true),
      ),
    );
  }
}

class _CompactionBlock extends StatelessWidget {
  final String text;
  const _CompactionBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return _CollapseBlock(
      label: context.l10n.compactedLabel,
      labelColor: colors.mutedForeground,
      initiallyOpen: false,
      textStyle: textOf(context).micro.copyWith(color: colors.mutedForeground),
      wrapper: (child) => Container(
        decoration: BoxDecoration(
          color: colors.muted.withValues(alpha: 0.4),
          borderRadius: AppRadius.rSm,
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: child,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: SelectableText(text, style: textOf(context).meta),
      ),
    );
  }
}

/// Minimal disclosure block without ExpansionTile chrome (no forced min
/// heights, no icon defaults) so spacing stays tight inside bubbles.
class _CollapseBlock extends StatefulWidget {
  final String label;
  final Color labelColor;
  final TextStyle textStyle;
  final bool initiallyOpen;
  final Widget child;
  final Widget Function(Widget child) wrapper;
  const _CollapseBlock({
    required this.label,
    required this.labelColor,
    required this.textStyle,
    required this.initiallyOpen,
    required this.wrapper,
    required this.child,
  });

  @override
  State<_CollapseBlock> createState() => _CollapseBlockState();
}

class _CollapseBlockState extends State<_CollapseBlock> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    return widget.wrapper(
      InkWell(
        onTap: () => setState(() => _open = !_open),
        borderRadius: AppRadius.rSm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _open
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  size: 14,
                  color: widget.labelColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(widget.label, style: widget.textStyle),
              ],
            ),
            if (_open) widget.child,
          ],
        ),
      ),
    );
  }
}
