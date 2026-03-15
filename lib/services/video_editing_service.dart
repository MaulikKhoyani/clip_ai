import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class VideoExportResult {
  final String? outputPath;
  final String? error;

  const VideoExportResult({this.outputPath, this.error});

  bool get isSuccess => outputPath != null && error == null;
}

/// Available filter presets for the video editor
class VideoFilter {
  final String name;
  final String ffmpegFilter; // empty string = no filter
  final String emoji;

  const VideoFilter({
    required this.name,
    required this.ffmpegFilter,
    required this.emoji,
  });
}

const videoFilters = [
  VideoFilter(name: 'Original', ffmpegFilter: '', emoji: '✨'),
  VideoFilter(name: 'Vivid', ffmpegFilter: 'eq=saturation=1.6:contrast=1.1', emoji: '🌈'),
  VideoFilter(name: 'Warm', ffmpegFilter: 'colorbalance=rs=0.15:gs=0.05:bs=-0.15', emoji: '🌅'),
  VideoFilter(name: 'Cool', ffmpegFilter: 'colorbalance=rs=-0.1:gs=0.0:bs=0.2', emoji: '🧊'),
  VideoFilter(name: 'B&W', ffmpegFilter: 'hue=s=0', emoji: '🎞️'),
  VideoFilter(name: 'Fade', ffmpegFilter: 'eq=contrast=0.75:saturation=0.6:brightness=0.08', emoji: '🌫️'),
  VideoFilter(name: 'Bright', ffmpegFilter: 'eq=brightness=0.12:saturation=1.2', emoji: '☀️'),
  VideoFilter(name: 'Drama', ffmpegFilter: 'eq=contrast=1.4:saturation=0.8:brightness=-0.05', emoji: '🎭'),
];

class VideoEditingService {
  static const _uuid = Uuid();

  Future<String> _getOutputPath() async {
    final dir = await getTemporaryDirectory();
    final exportDir = Directory('${dir.path}/clipai_exports');
    await exportDir.create(recursive: true);
    return '${exportDir.path}/${_uuid.v4()}.mp4';
  }

  /// Full export: trim + filter + speed + volume + rotation + flip
  ///
  /// [speed]    Playback speed multiplier (0.25 – 4.0). Default 1.0.
  /// [volume]   Audio volume multiplier (0.0 = mute, 1.0 = normal). Default 1.0.
  /// [rotation] Clockwise rotation in degrees: 0, 90, 180, or 270. Default 0.
  /// [flipH]    Mirror horizontally (hflip). Default false.
  /// [flipV]    Mirror vertically (vflip). Default false.
  Future<VideoExportResult> exportVideo({
    required String inputPath,
    required Duration startTrim,
    required Duration endTrim,
    VideoFilter? filter,
    bool isPro = false,
    bool addWatermark = false,
    double speed = 1.0,
    double volume = 1.0,
    int rotation = 0,
    bool flipH = false,
    bool flipV = false,
  }) async {
    final outputPath = await _getOutputPath();

    final startSec = startTrim.inMilliseconds / 1000.0;
    final durationSec =
        (endTrim.inMilliseconds - startTrim.inMilliseconds) / 1000.0;

    // ── Video filter chain ───────────────────────────────────────────────────
    // scale=-2 rounds to the nearest even number (required by libx264)
    final vFilters = <String>[isPro ? 'scale=1080:-2' : 'scale=720:-2'];

    // Speed — setpts changes PTS so video plays faster/slower
    if (speed != 1.0) {
      vFilters.add('setpts=PTS/${speed.toStringAsFixed(3)}');
    }

    // Rotation (transpose: 1=90°CW, 2=90°CCW; chain for 180°)
    switch (rotation) {
      case 90:
        vFilters.add('transpose=1');
      case 180:
        vFilters.addAll(['transpose=1', 'transpose=1']);
      case 270:
        vFilters.add('transpose=2');
    }

    if (flipH) vFilters.add('hflip');
    if (flipV) vFilters.add('vflip');

    // Color filter preset
    if (filter != null && filter.ffmpegFilter.isNotEmpty) {
      vFilters.add(filter.ffmpegFilter);
    }

    // ── Audio filter chain ───────────────────────────────────────────────────
    final aFilters = <String>[];

    // atempo range is 0.5–2.0; chain multiple filters for values outside that
    if (speed != 1.0) {
      aFilters.addAll(_buildAtempoChain(speed));
    }
    if (volume != 1.0) {
      aFilters.add('volume=${volume.toStringAsFixed(2)}');
    }

    final vfStr  = vFilters.join(',');
    final afFlag = aFilters.isNotEmpty ? '-af "${aFilters.join(',')}"' : '';
    final crf    = isPro ? 20 : 26;

    final command =
        '-ss $startSec -t $durationSec -i "$inputPath" '
        '-vf "$vfStr" $afFlag '
        '-c:v libx264 -preset ultrafast -crf $crf '
        '-c:a aac -b:a 128k '
        '"$outputPath"';

    return _execute(command, outputPath);
  }

  /// Returns a chain of atempo filter strings covering [speed].
  /// atempo only accepts 0.5–2.0, so we chain multiple calls.
  List<String> _buildAtempoChain(double speed) {
    final filters = <String>[];
    double remaining = speed;
    while (remaining > 2.0) {
      filters.add('atempo=2.0');
      remaining /= 2.0;
    }
    while (remaining < 0.5) {
      filters.add('atempo=0.5');
      remaining /= 0.5;
    }
    filters.add('atempo=${remaining.toStringAsFixed(3)}');
    return filters;
  }

  /// Quick trim with stream copy (fast, no re-encoding, no filters)
  Future<VideoExportResult> trimVideoFast({
    required String inputPath,
    required Duration startTrim,
    required Duration endTrim,
  }) async {
    final outputPath = await _getOutputPath();
    final startSec = startTrim.inMilliseconds / 1000.0;
    final durationSec =
        (endTrim.inMilliseconds - startTrim.inMilliseconds) / 1000.0;

    final command =
        '-ss $startSec -t $durationSec -i "$inputPath" -c copy "$outputPath"';

    return _execute(command, outputPath);
  }

  /// Get video duration in milliseconds
  Future<int> getVideoDurationMs(String path) async {
    int durationMs = 0;
    FFmpegKitConfig.enableStatisticsCallback((stats) {
      durationMs = stats.getTime().toInt();
    });
    await FFmpegKit.execute('-i $path -f null -');
    return durationMs;
  }

  Future<VideoExportResult> _execute(String command, String outputPath) async {
    debugPrint('[VideoEditingService] Running: $command');
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return VideoExportResult(outputPath: outputPath);
    } else {
      final logs = await session.getAllLogsAsString();
      debugPrint('[VideoEditingService] FFmpeg failed. Logs:\n$logs');
      return VideoExportResult(error: 'Export failed. Please try again.');
    }
  }
}
