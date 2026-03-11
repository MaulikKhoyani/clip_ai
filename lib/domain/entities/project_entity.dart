import 'package:equatable/equatable.dart';

class ProjectEntity extends Equatable {
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

  const ProjectEntity({
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

  bool get isDraft => status == 'draft';
  bool get isExported => status == 'exported';

  String get formattedDuration {
    if (durationSeconds == null) return '--:--';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        thumbnailPath,
        durationSeconds,
        templateId,
        status,
        createdAt,
        updatedAt,
      ];
}
