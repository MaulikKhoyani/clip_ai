import '../entities/template_entity.dart';
import '../../core/errors/result.dart';

abstract class TemplateRepository {
  Future<Result<List<TemplateEntity>>> getTemplates({String? category});
  Future<Result<TemplateEntity>> getTemplate(String id);
  Future<Result<List<TemplateEntity>>> getFeaturedTemplates({int limit = 5});
  Future<Result<void>> incrementDownloadCount(String id);
}
