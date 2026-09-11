import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pdfx/pdfx.dart';
import 'package:video_player/video_player.dart';

import '../api.dart';
import '../i18n.dart';
import '../services/download_service.dart';
import '../theme/app_theme.dart';
import '../services/media_cache.dart';

/// A media type derived from mime + filename.
enum MediaKind { image, audio, video, pdf, text, other }

MediaKind classifyMedia(String? mime, String? name) {
  final m = (mime ?? '').toLowerCase();
  final n = (name ?? '').toLowerCase();
  if (m.startsWith('image/')) return MediaKind.image;
  if (m.startsWith('audio/')) return MediaKind.audio;
  if (m.startsWith('video/')) return MediaKind.video;
  if (m == 'application/pdf' || n.endsWith('.pdf')) return MediaKind.pdf;
  if (m.startsWith('text/') ||
      m == 'application/json' ||
      m.endsWith('+json') ||
      n.endsWith('.md') ||
      n.endsWith('.txt') ||
      n.endsWith('.log') ||
      n.endsWith('.csv')) {
    return MediaKind.text;
  }
  // Extension fallback (servers often send octet-stream).
  if (n.endsWith('.png') ||
      n.endsWith('.jpg') ||
      n.endsWith('.jpeg') ||
      n.endsWith('.gif') ||
      n.endsWith('.webp')) {
    return MediaKind.image;
  }
  if (n.endsWith('.wav') ||
      n.endsWith('.mp3') ||
      n.endsWith('.m4a') ||
      n.endsWith('.ogg') ||
      n.endsWith('.aac')) {
    return MediaKind.audio;
  }
  if (n.endsWith('.mp4') ||
      n.endsWith('.webm') ||
      n.endsWith('.mov') ||
      n.endsWith('.mkv')) {
    return MediaKind.video;
  }
  return MediaKind.other;
}

String formatDurationLabel(Duration? d) {
  if (d == null || d.inMilliseconds < 0) return '--:--';
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String formatBytes(int n) {
  if (n >= 1024 * 1024) return '${(n / 1024 / 1024).toStringAsFixed(1)} MB';
  if (n >= 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
  return '$n B';
}

/// A media attachment rendered by type: images/videos open full-screen, audio
/// plays inline with a seek bar + time, pdf/text preview inline (expandable),
/// everything else falls back to a save-to-Downloads card. Bytes are fetched
/// through [MediaCache] (authenticated Connect GetFile → local temp file).
class MediaCard extends StatefulWidget {
  final AgentBindApi api;
  final String code;
  final String? name;
  final String? mime;
  final int? size;
  /// Compact (chip in a text run) vs full card (own file part).
  final bool compact;
  const MediaCard({
    super.key,
    required this.api,
    required this.code,
    this.name,
    this.mime,
    this.size,
    this.compact = false,
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  MediaKind? _kind;
  String? _mime;
  int _size = 0;
  String _name = '';

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    var mime = widget.mime;
    var size = widget.size ?? 0;
    var name = widget.name ?? widget.code;
    if (mime == null || mime.isEmpty || size == 0) {
      try {
        final probe = await widget.api.fileHead(widget.code);
        mime ??= probe.contentType;
        if (size == 0) size = probe.length;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _mime = mime;
      _size = size;
      _name = name;
      _kind = classifyMedia(mime, name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kind;
    if (kind == null) {
      return _chip(context, Icons.hourglass_empty_rounded,
          widget.name ?? widget.code, null);
    }
    switch (kind) {
      case MediaKind.image:
        return _ImageCard(
            api: widget.api,
            code: widget.code,
            name: _name,
            mime: _mime,
            size: _size,
            compact: widget.compact);
      case MediaKind.audio:
        return _AudioCard(
            api: widget.api,
            code: widget.code,
            name: _name,
            mime: _mime,
            size: _size,
            compact: widget.compact);
      case MediaKind.video:
        return _VideoCard(
            api: widget.api,
            code: widget.code,
            name: _name,
            mime: _mime,
            size: _size,
            compact: widget.compact);
      case MediaKind.pdf:
        return _InlinePreviewCard(
            api: widget.api,
            code: widget.code,
            name: _name,
            mime: _mime,
            size: _size,
            isPdf: true,
            compact: widget.compact);
      case MediaKind.text:
        return _InlinePreviewCard(
            api: widget.api,
            code: widget.code,
            name: _name,
            mime: _mime,
            size: _size,
            isPdf: false,
            compact: widget.compact);
      case MediaKind.other:
        return _chip(context, Icons.attach_file_rounded, _name,
            _size > 0 ? formatBytes(_size) : null,
            onTap: () => saveToDownloads(context, widget.api, widget.code, _name, _mime));
    }
  }

  Widget _chip(BuildContext context, IconData icon, String label,
      String? trailing,
      {VoidCallback? onTap}) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.5),
        borderRadius: AppRadius.rSm,
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        borderRadius: AppRadius.rSm,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colors.mutedForeground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: text.micro.copyWith(color: colors.foreground)),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              Text(trailing,
                  style: text.micro.copyWith(color: colors.mutedForeground)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Save an agent file into the public Downloads collection.
Future<void> saveToDownloads(BuildContext context, AgentBindApi api, String code,
    String name, String? mime) async {
  try {
    final where = await DownloadService(api).download(
      path: code,
      displayName: name,
      mimeType: (mime?.isNotEmpty == true) ? mime! : 'application/octet-stream',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.l10n.savedToDownloads(where)),
      duration: const Duration(seconds: 2),
    ));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.sendFailed('$e')),
        duration: const Duration(seconds: 2)));
  }
}

Future<void> openImageFullscreen(
    BuildContext context, AgentBindApi api, String code) async {
  try {
    final cache = MediaCache(api);
    final f = await cache.fileFor(code);
    if (!context.mounted) return;
    // ignore: use_build_context_synchronously
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => _FullscreenImage(file: f),
    );
  } catch (e) {
    if (!context.mounted) return;
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.sendFailed('$e'))));
  }
}

class _FullscreenImage extends StatelessWidget {
  final File file;
  const _FullscreenImage({required this.file});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 6,
            child: Image.file(file, fit: BoxFit.contain),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }
}

class _ImageCard extends StatelessWidget {
  final AgentBindApi api;
  final String code;
  final String name;
  final String? mime;
  final int size;
  final bool compact;
  const _ImageCard({
    required this.api,
    required this.code,
    required this.name,
    required this.mime,
    required this.size,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final thumb = ClipRRect(
      borderRadius: AppRadius.rMd,
      child: SizedBox(
        width: compact ? 180 : 220,
        height: compact ? 110 : 150,
        child: FutureBuilder<File>(
          future: MediaCache(api).fileFor(code, mime: mime, name: name),
          builder: (context, snap) {
            if (snap.hasData) {
              return Image.file(snap.data!, fit: BoxFit.cover);
            }
            if (snap.hasError) {
              return Center(
                  child: Icon(Icons.broken_image_rounded,
                      size: 28, color: colors.mutedForeground));
            }
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          },
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => openImageFullscreen(context, api, code),
            child: Hero(tag: 'img-$code', child: thumb),
          ),
          if (!compact && name.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('$name${size > 0 ? ' · ${formatBytes(size)}' : ''}',
                style: text.micro.copyWith(color: colors.mutedForeground)),
          ],
        ],
      ),
    );
  }
}

class _AudioCard extends StatefulWidget {
  final AgentBindApi api;
  final String code;
  final String name;
  final String? mime;
  final int size;
  final bool compact;
  const _AudioCard({
    required this.api,
    required this.code,
    required this.name,
    required this.mime,
    required this.size,
    required this.compact,
  });

  @override
  State<_AudioCard> createState() => _AudioCardState();
}

class _AudioCardState extends State<_AudioCard> {
  final _player = AudioPlayer();
  bool _ready = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  void initState() {
    super.initState();
    _load();
    _subs.add(_player.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() => _playing = s.playing);
    }));
    _subs.add(_player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    }));
    _subs.add(_player.durationStream.listen((d) {
      if (mounted && d != null) setState(() => _duration = d);
    }));
  }

  Future<void> _load() async {
    try {
      final f = await MediaCache(widget.api)
          .fileFor(widget.code, mime: widget.mime, name: widget.name);
      await _player.setFilePath(f.path);
      if (!mounted) return;
      setState(() {
        _ready = true;
        _duration = _player.duration;
      });
    } catch (_) {
      if (mounted) setState(() => _ready = false);
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_player.playing) {
      _player.pause();
    } else {
      if (_player.position >= (_player.duration ?? Duration.zero) &&
          (_player.duration ?? Duration.zero) > Duration.zero) {
        _player.seek(Duration.zero);
      }
      _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final total = _duration ?? _player.duration;
    final max = (total?.inMilliseconds ?? 0).toDouble();
    final pos = _position.inMilliseconds.toDouble().clamp(0.0, max).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.4),
        borderRadius: AppRadius.rMd,
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.graphic_eq_rounded, size: 16, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              if (!widget.compact)
                Expanded(
                  child: Text(widget.name,
                      overflow: TextOverflow.ellipsis,
                      style: text.micro.copyWith(color: colors.foreground)),
                )
              else
                const Spacer(),
              if (!_ready)
                const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  _playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                  size: 34,
                  color: colors.primary,
                ),
                onPressed: _ready ? _toggle : null,
              ),
              Expanded(
                child: Slider(
                  value: max <= 0 ? 0 : pos,
                  max: max <= 0 ? 1 : max,
                  onChanged: _ready && max > 0
                      ? (v) => _player.seek(Duration(milliseconds: v.round()))
                      : null,
                ),
              ),
              Text('${formatDurationLabel(_position)} / ${formatDurationLabel(total)}',
                  style: text.micro.copyWith(color: colors.mutedForeground)),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final AgentBindApi api;
  final String code;
  final String name;
  final String? mime;
  final int size;
  final bool compact;
  const _VideoCard({
    required this.api,
    required this.code,
    required this.name,
    required this.mime,
    required this.size,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _openFullscreen(context),
            child: ClipRRect(
              borderRadius: AppRadius.rMd,
              child: Container(
                width: compact ? 200 : 240,
                height: compact ? 120 : 150,
                color: Colors.black,
                child: const Center(
                  child: Icon(Icons.play_circle_fill_rounded,
                      size: 44, color: Colors.white),
                ),
              ),
            ),
          ),
          if (!compact && name.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('$name${size > 0 ? ' · ${formatBytes(size)}' : ''}',
                style: text.micro.copyWith(color: colors.mutedForeground)),
          ],
        ],
      ),
    );
  }

  Future<void> _openFullscreen(BuildContext context) async {
    try {
      final f = await MediaCache(api).fileFor(code, mime: mime, name: name);
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenVideo(file: f),
      ));
    } catch (e) {
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.sendFailed('$e'))));
    }
  }
}

class _FullscreenVideo extends StatefulWidget {
  final File file;
  const _FullscreenVideo({required this.file});
  @override
  State<_FullscreenVideo> createState() => _FullscreenVideoState();
}

class _FullscreenVideoState extends State<_FullscreenVideo> {
  VideoPlayerController? _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _ctrl;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(''),
      ),
      body: Center(
        child: c == null || !c.value.isInitialized
            ? const CircularProgressIndicator()
            : AspectRatio(
                aspectRatio: c.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(c),
                    VideoProgressIndicator(c, allowScrubbing: true),
                    IconButton(
                      iconSize: 56,
                      color: Colors.white,
                      icon: Icon(c.value.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded),
                      onPressed: () {
                        setState(() {
                          c.value.isPlaying ? c.pause() : c.play();
                        });
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Inline preview for PDF / text. Shows a collapsed summary that expands to a
/// bounded inline viewer (PDF pages or scrolling monospace text).
class _InlinePreviewCard extends StatefulWidget {
  final AgentBindApi api;
  final String code;
  final String name;
  final String? mime;
  final int size;
  final bool isPdf;
  final bool compact;
  const _InlinePreviewCard({
    required this.api,
    required this.code,
    required this.name,
    required this.mime,
    required this.size,
    required this.isPdf,
    required this.compact,
  });

  @override
  State<_InlinePreviewCard> createState() => _InlinePreviewCardState();
}

class _InlinePreviewCardState extends State<_InlinePreviewCard> {
  bool _open = false;
  String? _text;
  File? _file;
  bool _error = false;

  Future<void> _ensure() async {
    if (_text != null || _file != null || _error) return;
    try {
      final f = await MediaCache(widget.api)
          .fileFor(widget.code, mime: widget.mime, name: widget.name);
      if (widget.isPdf) {
        if (mounted) setState(() => _file = f);
      } else {
        final raw = await f.readAsString();
        if (mounted) {
          setState(() => _text = raw.length > 20000 ? raw.substring(0, 20000) : raw);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.35),
        borderRadius: AppRadius.rMd,
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              if (!_open) _ensure();
              setState(() => _open = !_open);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 2),
              child: Row(
                children: [
                  Icon(widget.isPdf ? Icons.picture_as_pdf_rounded : Icons.description_outlined,
                      size: 16, color: colors.mutedForeground),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(widget.name,
                        overflow: TextOverflow.ellipsis,
                        style: text.micro.copyWith(color: colors.foreground)),
                  ),
                  Text(widget.size > 0 ? formatBytes(widget.size) : '',
                      style: text.micro.copyWith(color: colors.mutedForeground)),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      size: 16, color: colors.mutedForeground),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
              child: _error
                  ? Text(context.l10n.noChanges,
                      style: text.micro.copyWith(color: colors.destructive))
                  : widget.isPdf
                      ? _pdfView()
                      : (_text == null
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ))
                          : Container(
                              constraints: const BoxConstraints(maxHeight: 260),
                              width: double.infinity,
                              child: SingleChildScrollView(
                                child: SelectableText(_text!,
                                    style: text.mono
                                        .copyWith(fontSize: 11)),
                              ),
                            )),
            ),
        ],
      ),
    );
  }

  Widget _pdfView() {
    final f = _file;
    if (f == null) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2)));
    }
    return SizedBox(
      height: 360,
      child: PdfViewPinch(
        key: ValueKey(f.path),
        controller: PdfControllerPinch(document: PdfDocument.openFile(f.path)),
      ),
    );
  }
}
