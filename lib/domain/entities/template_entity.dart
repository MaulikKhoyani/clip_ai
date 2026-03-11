import 'package:equatable/equatable.dart';

class TemplateEntity extends Equatable {
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
  final List<String> tags;

  const TemplateEntity({
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
    this.tags = const [],
  });

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        thumbnailUrl,
        isPro,
        downloadCount,
      ];
}
