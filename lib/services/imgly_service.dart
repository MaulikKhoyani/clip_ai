import 'package:flutter/services.dart';

class ImglyResult {
  final String? exportedVideoPath;
  final String? error;

  const ImglyResult({this.exportedVideoPath, this.error});

  bool get isSuccess => exportedVideoPath != null && error == null;
  bool get isCancelled => exportedVideoPath == null && error == null;
}

class ImglyService {
  static const _channel = MethodChannel('com.clipai.imgly/editor');

  Future<ImglyResult?> openCamera({bool isPro = false}) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'openCamera',
        {'isPro': isPro},
      );
      if (result == null) return null;
      return ImglyResult(
        exportedVideoPath: result['exportedVideoPath'] as String?,
        error: result['error'] as String?,
      );
    } on PlatformException catch (e) {
      return ImglyResult(error: e.message ?? 'Camera failed');
    }
  }

  Future<ImglyResult?> openEditor(
    List<String> videoPaths, {
    bool isPro = false,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'openVideoEditor',
        {'videoPaths': videoPaths, 'isPro': isPro},
      );
      if (result == null) return null;
      return ImglyResult(
        exportedVideoPath: result['exportedVideoPath'] as String?,
        error: result['error'] as String?,
      );
    } on PlatformException catch (e) {
      return ImglyResult(error: e.message ?? 'Editor failed');
    }
  }

  Future<ImglyResult?> openAiClipping(String videoPath) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'openAiClipping',
        {'videoPath': videoPath},
      );
      if (result == null) return null;
      return ImglyResult(
        exportedVideoPath: result['exportedVideoPath'] as String?,
        error: result['error'] as String?,
      );
    } on PlatformException catch (e) {
      return ImglyResult(error: e.message ?? 'AI Clipping failed');
    }
  }

  Future<ImglyResult?> openTemplates() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'openTemplates',
      );
      if (result == null) return null;
      return ImglyResult(
        exportedVideoPath: result['exportedVideoPath'] as String?,
        error: result['error'] as String?,
      );
    } on PlatformException catch (e) {
      return ImglyResult(error: e.message ?? 'Templates failed');
    }
  }

  Future<ImglyResult?> openDrafts() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'openDrafts',
      );
      if (result == null) return null;
      return ImglyResult(
        exportedVideoPath: result['exportedVideoPath'] as String?,
        error: result['error'] as String?,
      );
    } on PlatformException catch (e) {
      return ImglyResult(error: e.message ?? 'Drafts failed');
    }
  }
}
