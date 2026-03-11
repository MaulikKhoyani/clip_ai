import '../entities/project_entity.dart';
import '../../core/errors/result.dart';

abstract class ProjectRepository {
  Future<Result<List<ProjectEntity>>> getProjects();
  Future<Result<ProjectEntity>> getProject(String id);
  Future<Result<ProjectEntity>> createProject({
    required String title,
    String? templateId,
    Map<String, dynamic>? projectMeta,
  });
  Future<Result<ProjectEntity>> updateProject(ProjectEntity project);
  Future<Result<void>> deleteProject(String id);
  Future<Result<void>> updateThumbnail(String projectId, String thumbnailPath);
}
