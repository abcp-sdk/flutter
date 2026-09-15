import 'dart:io';

import 'package:video_player/video_player.dart';

import 'media_handle.dart';

/// Native: players take a filesystem path. just_audio accepts a `file://` URI
/// through `setUrl`, and `video_player` has a dedicated `.file` constructor.

VideoPlayerController videoControllerFor(MediaHandle handle) =>
    VideoPlayerController.file(File(handle.path!));

/// The URI to hand to `just_audio`'s `setUrl`.
String audioSourceFor(MediaHandle handle) => Uri.file(handle.path!).toString();
