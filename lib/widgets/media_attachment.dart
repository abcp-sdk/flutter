import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../api.dart';
import '../i18n.dart';
import '../services/download_service.dart';
import '../services/media_cache.dart';
import '../services/media_handle.dart';
import '../theme/app_theme.dart';
import 'dialogs.dart';

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

/// The source locator media_kit / Image should open for a [MediaHandle]:
/// a filesystem path on native, an object URL on web.
String _locator(MediaHandle h) => h.path ?? h.uri!;

/// A media attachment rendered by type: images open full-screen, audio plays
/// inline with a seek bar + time, video has a poster + full-screen player,
/// pdf/text preview inline (expandable), everything else a save card. All
/// through media_kit, which is cross-platform (mobile/desktop/web).
class MediaCard extends StatefulWidget {
  final AgentBindApi api;
  final String code;
  final String? name;
  final String? mime;
  final int? size;
  final bool compact;
  final String? localPath;
  const MediaCard({
    super.key,
    required this.api,
    required this.code,
    this.name,
    this.mime,
    this.size,
    this.compact = false,
    this.localPath,
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
    final hasCode = widget.code.isNotEmpty;
    if (hasCode && (mime == null || mime.isEmpty || size == 0)) {
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
            localPath: widget.localPath,
            compact: widget.compact);
      case MediaKind.audio:
        return _AudioCard(
            api: widget.api,
            code: widget.code,
            name: _name,
            mime: _mime,
            size: _size,
            localPath: widget.localPath,
            compact: widget.compact);
      case MediaKind.video:
        return _VideoCard(
            api: widget.api,
            code: widget.code,
            name: _name,
            mime: _mime,
            size: _size,
            localPath: widget.localPath,
            compact: widget.compact);
      case MediaKind.pdf:
        return _InlinePreviewCard(
            api: widget.api,
            code: widget.code,
            name: _name,
            mime: _mime,
            size: _size,
            localPath: widget.localPath,
            isPdf: true,
            compact: widget.compact);
      case MediaKind.text:
        return _InlinePreviewCard(
            api: widget.api,
            code: widget.code,
            name: _name,
            mime: _mime,
            size: _size,
            localPath: widget.localPath,
            isPdf: false,
            compact: widget.compact);
      case MediaKind.other:
        return _chip(context, Icons.attach_file_rounded, _name,
            _size > 0 ? formatBytes(_size) : null,
            onTap: () =>
                saveToDownloads(context, widget.api, widget.code, _name, _mime));
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

Future<void> saveToDownloads(BuildContext context, AgentBindApi api,
    String code, String name, String? mime) async {
  try {
    final where = await DownloadService(api).download(
      path: code,
      displayName: name,
      mimeType: (mime?.isNotEmpty == true) ? mime! : 'application/octet-stream',
    );
    if (!context.mounted) return;
    showToast(context, context.l10n.savedToDownloads(where));
  } catch (e) {
    if (!context.mounted) return;
    showErrorToast(context, context.l10n.sendFailed('$e'));
  }
}

Future<void> openImageFullscreen(
    BuildContext context, AgentBindApi api, String code,
    {String? localPath}) async {
  try {
    final h = await MediaCache(api).fileFor(code, localPath: localPath);
    if (!context.mounted) return;
    // ignore: use_build_context_synchronously
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => _FullscreenImage(provider: imageProviderFor(h)),
    );
  } catch (e) {
    if (!context.mounted) return;
    // ignore: use_build_context_synchronously
    showErrorToast(context, context.l10n.sendFailed('$e'));
  }
}

class _FullscreenImage extends StatelessWidget {
  final Object provider;
  const _FullscreenImage({required this.provider});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 6,
            child: Image(image: provider as ImageProvider, fit: BoxFit.contain),
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
  final String? localPath;
  final bool compact;
  const _ImageCard({
    required this.api,
    required this.code,
    required this.name,
    required this.mime,
    required this.size,
    this.localPath,
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
        child: FutureBuilder<MediaHandle>(
          future: MediaCache(api)
              .fileFor(code, mime: mime, name: name, localPath: localPath),
          builder: (context, snap) {
            if (snap.hasData) {
              return Image(image: imageProviderFor(snap.data!), fit: BoxFit.cover);
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
            onTap: () =>
                openImageFullscreen(context, api, code, localPath: localPath),
            child: thumb,
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

/// Audio card: media_kit plays a file path (native) or object URL (web).
class _AudioCard extends StatefulWidget {
  final AgentBindApi api;
  final String code;
  final String name;
  final String? mime;
  final int size;
  final String? localPath;
  final bool compact;
  const _AudioCard({
    required this.api,
    required this.code,
    required this.name,
    required this.mime,
    required this.size,
    this.localPath,
    required this.compact,
  });

  @override
  State<_AudioCard> createState() => _AudioCardState();
}

class _AudioCardState extends State<_AudioCard> {
  final _player = Player();
  bool _ready = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  void initState() {
    super.initState();
    _load();
    _subs.add(_player.stream.playing.listen((p) {
      if (mounted) setState(() => _playing = p);
    }));
    _subs.add(_player.stream.position.listen((p) {
      if (mounted) setState(() => _position = p);
    }));
    _subs.add(_player.stream.duration.listen((d) {
      if (mounted && d > Duration.zero) setState(() => _duration = d);
    }));
  }

  Future<void> _load() async {
    try {
      final h = await MediaCache(widget.api).fileFor(widget.code,
          mime: widget.mime, name: widget.name, localPath: widget.localPath);
      // NEVER autoplay: open paused; the user taps the play button to start.
      await _player.open(Media(_locator(h)), play: false);
      if (!mounted) return;
      setState(() {
        _ready = true;
        if (_player.state.duration > Duration.zero) {
          _duration = _player.state.duration;
        }
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
    if (_player.state.playing) {
      _player.pause();
    } else {
      final d = _player.state.duration;
      if (d > Duration.zero && _player.state.position >= d) {
        _player.seek(Duration.zero);
      }
      _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final total = _duration ?? _player.state.duration;
    final max = total.inMilliseconds.toDouble();
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
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  _playing
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
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
              Text(
                  '${formatDurationLabel(_position)} / ${formatDurationLabel(total)}',
                  style: text.micro.copyWith(color: colors.mutedForeground)),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
        ],
      ),
    );
  }
}

/// Video card: a poster (first frame, native only) + a full-screen player.
class _VideoCard extends StatefulWidget {
  final AgentBindApi api;
  final String code;
  final String name;
  final String? mime;
  final int size;
  final String? localPath;
  final bool compact;
  const _VideoCard({
    required this.api,
    required this.code,
    required this.name,
    required this.mime,
    required this.size,
    this.localPath,
    required this.compact,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  final _player = Player();
  VideoController? _controller;
  bool _ready = false;
  Duration? _duration;

  @override
  void initState() {
    super.initState();
    _load();
    _player.stream.duration.listen((d) {
      if (mounted && d > Duration.zero) setState(() => _duration = d);
    });
  }

  Future<void> _load() async {
    try {
      final h = await MediaCache(widget.api).fileFor(widget.code,
          mime: widget.mime, name: widget.name, localPath: widget.localPath);
      await _player.open(Media(_locator(h)), play: false);
      final c = VideoController(_player);
      if (!mounted) return;
      setState(() {
        _controller = c;
        _ready = true;
        if (_player.state.duration > Duration.zero) {
          _duration = _player.state.duration;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _ready = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _openFullscreen(BuildContext context) async {
    if (_controller == null) return;
    await Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullscreenVideo(player: _player, controller: _controller!),
    ));
  }

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
                width: widget.compact ? 200 : 240,
                height: widget.compact ? 120 : 150,
                color: Colors.black,
                child: _ready
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Video(
                            controller: _controller!,
                            controls: NoVideoControls,
                          ),
                          const Center(
                            child: Icon(Icons.play_circle_fill_rounded,
                                size: 44, color: Colors.white70),
                          ),
                        ],
                      )
                    : const Center(
                        child: Icon(Icons.videocam_outlined,
                            size: 28, color: Colors.white54),
                      ),
              ),
            ),
          ),
          if (!widget.compact && widget.name.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
                '${widget.name}'
                '${widget.size > 0 ? ' · ${formatBytes(widget.size)}' : ''}'
                '${_duration != null ? ' · ${formatDurationLabel(_duration)}' : ''}',
                style: text.micro.copyWith(color: colors.mutedForeground)),
          ],
        ],
      ),
    );
  }
}

class _FullscreenVideo extends StatelessWidget {
  final Player player;
  final VideoController controller;
  const _FullscreenVideo({required this.player, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: Video(controller: controller, controls: AdaptiveVideoControls)),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// PDF / text preview: fetch bytes, render text inline (expandable) or show a
/// PDF placeholder with a download action (keeps the dependency surface small
/// and works on every platform).
class _InlinePreviewCard extends StatefulWidget {
  final AgentBindApi api;
  final String code;
  final String name;
  final String? mime;
  final int size;
  final String? localPath;
  final bool isPdf;
  final bool compact;
  const _InlinePreviewCard({
    required this.api,
    required this.code,
    required this.name,
    required this.mime,
    required this.size,
    this.localPath,
    required this.isPdf,
    required this.compact,
  });

  @override
  State<_InlinePreviewCard> createState() => _InlinePreviewCardState();
}

class _InlinePreviewCardState extends State<_InlinePreviewCard> {
  bool _open = false;
  String? _text;
  bool _error = false;

  Future<void> _ensure() async {
    if (_text != null || _error) return;
    try {
      final h = await MediaCache(widget.api).fileFor(widget.code,
          mime: widget.mime, name: widget.name, localPath: widget.localPath);
      if (!widget.isPdf) {
        final raw = String.fromCharCodes(h.bytes);
        if (mounted) {
          setState(() =>
              _text = raw.length > 20000 ? raw.substring(0, 20000) : raw);
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
              setState(() => _open = !_open);
              if (_open) _ensure();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                      widget.isPdf
                          ? Icons.picture_as_pdf_outlined
                          : Icons.description_outlined,
                      size: 16,
                      color: colors.mutedForeground),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(widget.name,
                        overflow: TextOverflow.ellipsis,
                        style: text.micro.copyWith(color: colors.foreground)),
                  ),
                  if (widget.size > 0)
                    Text(formatBytes(widget.size),
                        style:
                            text.micro.copyWith(color: colors.mutedForeground)),
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      size: 18, color: colors.mutedForeground),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
              child: widget.isPdf
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => saveToDownloads(context, widget.api,
                            widget.code, widget.name, widget.mime),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: Text(context.l10n.save),
                      ),
                    )
                  : Text(_error ? context.l10n.loadError('') : (_text ?? '...'),
                      style: text.micro),
            ),
        ],
      ),
    );
  }
}

/// A small, fixed-size attachment tile: a square thumbnail (image) or a type
/// icon, no file name. Uniform so several fit per line. An optional [overlay]
/// (status / remove badge) is drawn in the corner.
class AttachmentTag extends StatelessWidget {
  final AgentBindApi api;
  final String code;
  final String? name;
  final String? mime;
  final int? size;
  final String? localPath;
  final Widget? overlay;
  final VoidCallback? onTap;
  final double dimension;
  const AttachmentTag({
    super.key,
    required this.api,
    required this.code,
    this.name,
    this.mime,
    this.size,
    this.localPath,
    this.overlay,
    this.onTap,
    this.dimension = 48,
  });

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final kind = classifyMedia(mime, name);
    final isImg = kind == MediaKind.image;

    Widget content;
    if (isImg) {
      content = FutureBuilder<MediaHandle>(
        future: MediaCache(api)
            .fileFor(code, mime: mime, name: name, localPath: localPath),
        builder: (context, snap) {
          if (snap.hasData) {
            return Image(image: imageProviderFor(snap.data!), fit: BoxFit.cover);
          }
          if (snap.hasError) {
            return Icon(Icons.broken_image_outlined,
                size: 18, color: colors.mutedForeground);
          }
          return const Center(
              child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2)));
        },
      );
    } else if (kind == MediaKind.audio) {
      content = _MediaThumb(
          api: api,
          code: code,
          name: name,
          mime: mime,
          localPath: localPath,
          kind: kind);
    } else if (kind == MediaKind.video) {
      content = Icon(Icons.videocam_outlined,
          size: 20, color: colors.mutedForeground);
    } else {
      content = Icon(_iconFor(kind), size: 20, color: colors.mutedForeground);
    }

    return SizedBox(
      width: dimension,
      height: dimension,
      child: Material(
        color: colors.muted.withValues(alpha: 0.5),
        borderRadius: AppRadius.rSm,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InkWell(onTap: onTap, child: Center(child: content)),
            if (overlay != null)
              Positioned(top: 0, right: 0, child: overlay!),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(MediaKind k) => switch (k) {
        MediaKind.audio => Icons.graphic_eq_rounded,
        MediaKind.video => Icons.videocam_outlined,
        MediaKind.pdf => Icons.picture_as_pdf_outlined,
        MediaKind.text => Icons.description_outlined,
        _ => Icons.attach_file_rounded,
      };
}

/// Audio thumbnail: a type icon with the clip's DURATION underneath.
class _MediaThumb extends StatefulWidget {
  final AgentBindApi api;
  final String code;
  final String? name;
  final String? mime;
  final String? localPath;
  final MediaKind kind;
  const _MediaThumb({
    required this.api,
    required this.code,
    required this.name,
    required this.mime,
    required this.localPath,
    required this.kind,
  });

  @override
  State<_MediaThumb> createState() => _MediaThumbState();
}

class _MediaThumbState extends State<_MediaThumb> {
  final _player = Player();
  Duration? _duration;
  StreamSubscription<dynamic>? _durSub;

  @override
  void initState() {
    super.initState();
    _load();
    _durSub = _player.stream.duration.listen((d) {
      if (mounted && d > Duration.zero) setState(() => _duration = d);
    });
  }

  Future<void> _load() async {
    try {
      final h = await MediaCache(widget.api).fileFor(widget.code,
          mime: widget.mime, name: widget.name, localPath: widget.localPath);
      await _player.open(Media(_locator(h)), play: false);
      if (mounted && _player.state.duration > Duration.zero) {
        setState(() => _duration = _player.state.duration);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.graphic_eq_rounded, size: 18, color: colors.primary),
        const SizedBox(height: 2),
        Text(
          formatDurationLabel(_duration),
          style: text.micro.copyWith(
              fontSize: 9, height: 1.0, color: colors.mutedForeground),
        ),
      ],
    );
  }
}

/// Open one attachment: image/video → full-screen, everything else → a small
/// dialog card (audio player / pdf / text preview / download).
Future<void> showAttachment(BuildContext context, AgentBindApi api, String code,
    String? name, String? mime, int? size) async {
  if (code.isEmpty) return;
  final kind = classifyMedia(mime, name);
  if (kind == MediaKind.image) {
    await openImageFullscreen(context, api, code);
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MediaCard(api: api, code: code, name: name, mime: mime, size: size),
          ],
        ),
      ),
    ),
  );
}
