import 'package:video_player/video_player.dart';

import 'media_handle.dart';

/// Web: players consume the blob object URL. `video_player` needs the network
/// constructor (blob: URLs work through it in the browser), and just_audio's
/// `setUrl` takes the URI string directly.

VideoPlayerController videoControllerFor(MediaHandle handle) =>
    VideoPlayerController.networkUrl(Uri.parse(handle.uri!));

/// The URI to hand to `just_audio`'s `setUrl`.
String audioSourceFor(MediaHandle handle) => handle.uri!;
