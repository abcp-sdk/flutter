import 'dart:io';
import 'dart:typed_data';

/// A fresh temp file path for a recording (native only).
Future<String> tempVoicePath() async {
  final dir = await Directory.systemTemp.createTemp('voice');
  return '${dir.path}/voice-${DateTime.now().millisecondsSinceEpoch}.wav';
}

/// Read the recorded bytes. [result] is what `AudioRecorder.stop()` returned:
/// on native that is a path; [fallbackPath] is the path we asked it to write.
Future<Uint8List?> readVoiceBytes(String result, String fallbackPath) async {
  final p = result.isNotEmpty ? result : fallbackPath;
  final f = File(p);
  if (!await f.exists()) return null;
  return f.readAsBytes();
}

/// Delete a stale recording file (native only).
Future<void> deleteVoiceFile(String path) async {
  try {
    final f = File(path);
    if (await f.exists()) await f.delete();
  } catch (_) {}
}
