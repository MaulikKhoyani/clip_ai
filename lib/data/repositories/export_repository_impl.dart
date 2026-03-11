import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import 'package:clip_ai/core/errors/app_exceptions.dart';
import 'package:clip_ai/core/errors/result.dart';
import 'package:clip_ai/data/datasources/supabase_datasource.dart';
import 'package:clip_ai/domain/entities/export_entity.dart';
import 'package:clip_ai/domain/repositories/export_repository.dart';

class ExportRepositoryImpl implements ExportRepository {
  final SupabaseDataSource _dataSource;

  ExportRepositoryImpl(this._dataSource);

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  @override
  Future<Result<ExportEntity>> logExport({
    required String projectId,
    required String format,
    required String resolution,
    double? fileSizeMb,
    int? durationSeconds,
    bool usedAiCaptions = false,
    bool usedBgRemoval = false,
  }) async {
    try {
      final userId = _userId;
      if (userId == null) {
        return const Failure(AuthException('Not authenticated'));
      }
      final data = <String, dynamic>{
        'user_id': userId,
        'project_id': projectId,
        'format': format,
        'resolution': resolution,
        if (fileSizeMb != null) 'file_size_mb': fileSizeMb,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        'used_ai_captions': usedAiCaptions,
        'used_bg_removal': usedBgRemoval,
      };
      final model = await _dataSource.logExport(data);
      return Success(model.toEntity());
    } catch (e) {
      return Failure(ExportException(e.toString()));
    }
  }

  @override
  Future<Result<List<ExportEntity>>> getExports() async {
    try {
      final userId = _userId;
      if (userId == null) {
        return const Failure(AuthException('Not authenticated'));
      }
      final models = await _dataSource.getExports(userId);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }
}
