import '../../domain/entities/project_entity.dart';

class ProjectModel {
  final String id;
  final String userId;
  final String title;
  final String? thumbnailPath;
  final int? durationSeconds;
  final String? templateId;
  final Map<String, dynamic> projectMeta;
  final String status;
  final DateTime? lastExportedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectModel({
    required this.id,
    required this.userId,
    required this.title,
    this.thumbnailPath,
    this.durationSeconds,
    this.templateId,
    this.projectMeta = const {},
    this.status = 'draft',
    this.lastExportedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      thumbnailPath: json['thumbnail_path'] as String?,
      durationSeconds: json['duration_seconds'] as int?,
      templateId: json['template_id'] as String?,
      projectMeta: (json['project_meta'] as Map<String, dynamic>?) ?? {},
      status: json['status'] as String? ?? 'draft',
      lastExportedAt: json['last_exported_at'] != null
          ? DateTime.parse(json['last_exported_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'thumbnail_path': thumbnailPath,
      'duration_seconds': durationSeconds,
      'template_id': templateId,
      'project_meta': projectMeta,
      'status': status,
      'last_exported_at': lastExportedAt?.toIso8601String(),
    };
  }

  ProjectEntity toEntity() {
    return ProjectEntity(
      id: id,
      userId: userId,
      title: title,
      thumbnailPath: thumbnailPath,
      durationSeconds: durationSeconds,
      templateId: templateId,
      projectMeta: projectMeta,
      status: status,
      lastExportedAt: lastExportedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
