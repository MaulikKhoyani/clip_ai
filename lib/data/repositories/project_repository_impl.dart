import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import 'package:clip_ai/core/errors/app_exceptions.dart';
import 'package:clip_ai/core/errors/result.dart';
import 'package:clip_ai/data/datasources/local_datasource.dart';
import 'package:clip_ai/data/datasources/supabase_datasource.dart';
import 'package:clip_ai/domain/entities/project_entity.dart';
import 'package:clip_ai/domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final SupabaseDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;

  ProjectRepositoryImpl(this._remoteDataSource, this._localDataSource);

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  @override
  Future<Result<List<ProjectEntity>>> getProjects() async {
    try {
      final userId = _userId;
      if (userId == null) {
        return const Failure(AuthException('Not authenticated'));
      }
      final models = await _remoteDataSource.getProjects(userId);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }

  @override
  Future<Result<ProjectEntity>> getProject(String id) async {
    try {
      final model = await _remoteDataSource.getProject(id);
      return Success(model.toEntity());
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }

  @override
  Future<Result<ProjectEntity>> createProject({
    required String title,
    String? templateId,
    Map<String, dynamic>? projectMeta,
  }) async {
    try {
      final userId = _userId;
      if (userId == null) {
        return const Failure(AuthException('Not authenticated'));
      }
      final data = <String, dynamic>{
        'user_id': userId,
        'title': title,
        if (templateId != null) 'template_id': templateId,
        if (projectMeta != null) 'project_meta': projectMeta,
      };
      final model = await _remoteDataSource.createProject(data);
      return Success(model.toEntity());
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }

  @override
  Future<Result<ProjectEntity>> updateProject(ProjectEntity project) async {
    try {
      final data = <String, dynamic>{
        'title': project.title,
        'thumbnail_path': project.thumbnailPath,
        'duration_seconds': project.durationSeconds,
        'template_id': project.templateId,
        'project_meta': project.projectMeta,
        'status': project.status,
        'last_exported_at': project.lastExportedAt?.toIso8601String(),
      };
      final model = await _remoteDataSource.updateProject(project.id, data);
      return Success(model.toEntity());
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteProject(String id) async {
    try {
      await _remoteDataSource.deleteProject(id);
      return const Success(null);
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateThumbnail(
    String projectId,
    String thumbnailPath,
  ) async {
    try {
      await _remoteDataSource.updateProject(projectId, {
        'thumbnail_path': thumbnailPath,
      });
      return const Success(null);
    } catch (e) {
      return Failure(NetworkException(e.toString()));
    }
  }
}
