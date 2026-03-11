import '../../domain/entities/export_entity.dart';

class ExportModel {
  final String id;
  final String userId;
  final String? projectId;
  final String format;
  final String resolution;
  final double? fileSizeMb;
  final int? durationSeconds;
  final bool usedAiCaptions;
  final bool usedBgRemoval;
  final DateTime exportedAt;

  const ExportModel({
    required this.id,
    required this.userId,
    this.projectId,
    required this.format,
    required this.resolution,
    this.fileSizeMb,
    this.durationSeconds,
    this.usedAiCaptions = false,
    this.usedBgRemoval = false,
    required this.exportedAt,
  });

  factory ExportModel.fromJson(Map<String, dynamic> json) {
    return ExportModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String?,
      format: json['format'] as String,
      resolution: json['resolution'] as String,
      fileSizeMb: (json['file_size_mb'] as num?)?.toDouble(),
      durationSeconds: json['duration_seconds'] as int?,
      usedAiCaptions: json['used_ai_captions'] as bool? ?? false,
      usedBgRemoval: json['used_bg_removal'] as bool? ?? false,
      exportedAt: DateTime.parse(json['exported_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'project_id': projectId,
      'format': format,
      'resolution': resolution,
      'file_size_mb': fileSizeMb,
      'duration_seconds': durationSeconds,
      'used_ai_captions': usedAiCaptions,
      'used_bg_removal': usedBgRemoval,
    };
  }

  ExportEntity toEntity() {
    return ExportEntity(
      id: id,
      userId: userId,
      projectId: projectId,
      format: format,
      resolution: resolution,
      fileSizeMb: fileSizeMb,
      durationSeconds: durationSeconds,
      usedAiCaptions: usedAiCaptions,
      usedBgRemoval: usedBgRemoval,
      exportedAt: exportedAt,
    );
  }
}
