import 'package:ve_sdk_flutter/ve_sdk_flutter.dart';
import 'package:ve_sdk_flutter/features_config.dart';
import 'package:ve_sdk_flutter/export_data.dart';
import 'package:ve_sdk_flutter/export_result.dart';

import 'package:clip_ai/core/constants/api_constants.dart';

class BanubaService {
  final VeSdkFlutter _sdk;

  BanubaService(this._sdk);

  FeaturesConfig buildConfig() {
    return FeaturesConfigBuilder()
        .setAudioBrowser(AudioBrowser.fromSource(AudioBrowserSource.local))
        .setCameraConfig(const CameraConfig(
          supportsBeauty: true,
          supportsColorEffects: true,
          supportsMasks: true,
          recordModes: [RecordMode.video, RecordMode.photo],
        ))
        .setEditorConfig(const EditorConfig(
          enableVideoAspectFill: true,
          supportsVisualEffects: true,
          supportsColorEffects: true,
          supportsVoiceOver: true,
          supportsAudioEditing: true,
        ))
        .setDraftsConfig(DraftsConfig.fromOption(DraftsOption.askToSave))
        .setVideoDurationConfig(const VideoDurationConfig(
          maxTotalVideoDuration: 180.0,
          videoDurations: [60.0, 30.0, 15.0],
        ))
        .enableEditorV2(true)
        .build();
  }

  ExportData buildExportData({required bool isPro}) {
    return ExportData(
      exportedVideos: [
        ExportedVideo(
          fileName: 'clipai_export',
          videoResolution:
              isPro ? VideoResolution.fhd1080p : VideoResolution.hd720p,
          useHevcIfPossible: true,
        ),
      ],
      watermark: isPro
          ? null
          : const Watermark(
              imagePath: 'assets/watermark/clipai_watermark.png',
              alignment: WatermarkAlignment.bottomRight,
            ),
    );
  }

  String get _token => ApiConstants.banubaLicenseToken;

  Future<ExportResult?> openCamera({ExportData? exportData}) {
    return _sdk.openCameraScreen(
      _token,
      buildConfig(),
      exportData: exportData,
    );
  }

  Future<ExportResult?> openTrimmer(List<String> videoPaths,
      {ExportData? exportData}) {
    return _sdk.openTrimmerScreen(
      _token,
      buildConfig(),
      videoPaths,
      exportData: exportData,
    );
  }

  Future<ExportResult?> openEditor(List<String> videoPaths,
      {ExportData? exportData}) {
    return _sdk.openEditorScreen(
      _token,
      buildConfig(),
      videoPaths,
      exportData: exportData,
    );
  }

  Future<ExportResult?> openTemplates({ExportData? exportData}) {
    return _sdk.openTemplatesScreen(
      _token,
      buildConfig(),
      exportData: exportData,
    );
  }

  Future<ExportResult?> openDrafts({ExportData? exportData}) {
    return _sdk.openDraftsScreen(
      _token,
      buildConfig(),
      exportData: exportData,
    );
  }

  Future<ExportResult?> openAiClipping({ExportData? exportData}) {
    return _sdk.openAiClippingScreen(
      _token,
      buildConfig(),
      exportData: exportData,
    );
  }
}
