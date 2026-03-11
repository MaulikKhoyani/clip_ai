import '../entities/export_entity.dart';
import '../../core/errors/result.dart';

abstract class ExportRepository {
  Future<Result<ExportEntity>> logExport({
    required String projectId,
    required String format,
    required String resolution,
    double? fileSizeMb,
    int? durationSeconds,
    bool usedAiCaptions = false,
    bool usedBgRemoval = false,
  });
  Future<Result<List<ExportEntity>>> getExports();
}
