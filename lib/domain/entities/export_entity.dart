import 'package:equatable/equatable.dart';

class ExportEntity extends Equatable {
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

  const ExportEntity({
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

  @override
  List<Object?> get props => [id, userId, projectId, format, resolution, exportedAt];
}
