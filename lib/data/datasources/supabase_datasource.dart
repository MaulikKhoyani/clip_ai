import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clip_ai/data/models/user_model.dart';
import 'package:clip_ai/data/models/project_model.dart';
import 'package:clip_ai/data/models/template_model.dart';
import 'package:clip_ai/data/models/export_model.dart';

class SupabaseDataSource {
  final SupabaseClient _client;

  SupabaseDataSource(this._client);

  // ── Profiles ──

  Future<UserModel> getProfile(String userId) async {
    final response =
        await _client.from('profiles').select().eq('id', userId).single();
    return UserModel.fromJson(response);
  }

  Future<UserModel> createProfile(Map<String, dynamic> data) async {
    final response = await _client
        .from('profiles')
        .upsert(data)
        .select()
        .single();
    return UserModel.fromJson(response);
  }

  Future<UserModel> updateProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client
        .from('profiles')
        .update(data)
        .eq('id', userId)
        .select()
        .single();
    return UserModel.fromJson(response);
  }

  // ── Projects ──

  Future<List<ProjectModel>> getProjects(String userId) async {
    final response = await _client
        .from('projects')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return (response as List)
        .map((json) => ProjectModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ProjectModel> getProject(String id) async {
    final response =
        await _client.from('projects').select().eq('id', id).single();
    return ProjectModel.fromJson(response);
  }

  Future<ProjectModel> createProject(Map<String, dynamic> data) async {
    final response =
        await _client.from('projects').insert(data).select().single();
    return ProjectModel.fromJson(response);
  }

  Future<ProjectModel> updateProject(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client
        .from('projects')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return ProjectModel.fromJson(response);
  }

  Future<void> deleteProject(String id) async {
    await _client.from('projects').delete().eq('id', id);
  }

  // ── Templates ──

  Future<List<TemplateModel>> getTemplates({String? category}) async {
    var query = _client.from('templates').select();
    if (category != null) {
      query = query.eq('category', category);
    }
    final response = await query.order('sort_order', ascending: true);
    return (response as List)
        .map((json) => TemplateModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<TemplateModel>> getFeaturedTemplates(int limit) async {
    final response = await _client
        .from('templates')
        .select()
        .order('download_count', ascending: false)
        .limit(limit);
    return (response as List)
        .map((json) => TemplateModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> incrementTemplateDownload(String id) async {
    await _client.rpc('increment_template_download', params: {'t_id': id});
  }

  // ── FCM Tokens ──

  Future<void> saveFcmToken(String userId, String token) async {
    await _client
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', userId);
  }

  // ── Exports ──

  Future<ExportModel> logExport(Map<String, dynamic> data) async {
    final response =
        await _client.from('exports').insert(data).select().single();
    return ExportModel.fromJson(response);
  }

  Future<List<ExportModel>> getExports(String userId) async {
    final response = await _client
        .from('exports')
        .select()
        .eq('user_id', userId)
        .order('exported_at', ascending: false);
    return (response as List)
        .map((json) => ExportModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
