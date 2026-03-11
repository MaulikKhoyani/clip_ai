import 'package:clip_ai/core/errors/app_exceptions.dart';
import 'package:clip_ai/core/errors/result.dart';
import 'package:clip_ai/data/datasources/supabase_datasource.dart';
import 'package:clip_ai/domain/entities/template_entity.dart';
import 'package:clip_ai/domain/repositories/template_repository.dart';

class TemplateRepositoryImpl implements TemplateRepository {
  final SupabaseDataSource _dataSource;

  TemplateRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<TemplateEntity>>> getTemplates({
    String? category,
  }) async {
    try {
      final models = await _dataSource.getTemplates(category: category);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }

  @override
  Future<Result<TemplateEntity>> getTemplate(String id) async {
    try {
      final models = await _dataSource.getTemplates();
      final model = models.firstWhere((m) => m.id == id);
      return Success(model.toEntity());
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }

  @override
  Future<Result<List<TemplateEntity>>> getFeaturedTemplates({
    int limit = 5,
  }) async {
    try {
      final models = await _dataSource.getFeaturedTemplates(limit);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }

  @override
  Future<Result<void>> incrementDownloadCount(String id) async {
    try {
      await _dataSource.incrementTemplateDownload(id);
      return const Success(null);
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }
}
