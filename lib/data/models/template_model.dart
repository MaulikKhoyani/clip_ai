import '../../domain/entities/template_entity.dart';

class TemplateModel {
  final String id;
  final String name;
  final String? description;
  final String category;
  final String thumbnailUrl;
  final String? previewVideoUrl;
  final Map<String, dynamic> templateData;
  final String aspectRatio;
  final int? durationSeconds;
  final bool isPro;
  final int downloadCount;
  final int sortOrder;
  final List<String> tags;
  final DateTime createdAt;

  const TemplateModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.thumbnailUrl,
    this.previewVideoUrl,
    this.templateData = const {},
    this.aspectRatio = '9:16',
    this.durationSeconds,
    this.isPro = false,
    this.downloadCount = 0,
    this.sortOrder = 0,
    this.tags = const [],
    required this.createdAt,
  });

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    return TemplateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      thumbnailUrl: json['thumbnail_url'] as String,
      previewVideoUrl: json['preview_video_url'] as String?,
      templateData: (json['template_data'] as Map<String, dynamic>?) ?? {},
      aspectRatio: json['aspect_ratio'] as String? ?? '9:16',
      durationSeconds: json['duration_seconds'] as int?,
      isPro: json['is_pro'] as bool? ?? false,
      downloadCount: json['download_count'] as int? ?? 0,
      sortOrder: json['sort_order'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  TemplateEntity toEntity() {
    return TemplateEntity(
      id: id,
      name: name,
      description: description,
      category: category,
      thumbnailUrl: thumbnailUrl,
      previewVideoUrl: previewVideoUrl,
      templateData: templateData,
      aspectRatio: aspectRatio,
      durationSeconds: durationSeconds,
      isPro: isPro,
      downloadCount: downloadCount,
      tags: tags,
    );
  }
}
