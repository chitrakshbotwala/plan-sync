import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:plan_sync/core/services/api_client.dart';
import 'package:plan_sync/features/schedule/repository/sections_repository.dart';
import 'package:plan_sync/util/logger.dart';

class SectionsRepositoryImpl implements SectionsRepository {
  SectionsRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  String get _sectionsUrl =>
      'https://gitlab.com/delwinn/plan-sync/-/raw/${_apiClient.branch}/res/sections.json';

  String get _electivesUrl =>
      'https://gitlab.com/delwinn/plan-sync/-/raw/${_apiClient.branch}/res/electives.json';

  Future<Map<String, dynamic>> _fetchJsonData(String url) async {
    try {
      final response = await _apiClient.dio.get(url);
      return jsonDecode(response.data) as Map<String, dynamic>;
    } on DioException catch (e) {
      Logger.e('SectionsRepository._fetchJsonData DioException: $e');
      rethrow;
    } catch (e) {
      Logger.e('SectionsRepository._fetchJsonData failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getYears() async {
    final data = await _fetchJsonData(_sectionsUrl);
    return List<String>.from(data.keys);
  }

  @override
  Future<List<String>> getSemesters(String year) async {
    final data = await _fetchJsonData(_sectionsUrl);
    final yearData = data[year] as Map<String, dynamic>?;
    return yearData == null ? [] : List<String>.from(yearData.keys);
  }

  @override
  Future<Map<String, String>> getSections(String year, String semester) async {
    final data = await _fetchJsonData(_sectionsUrl);
    final semData = (data[year] as Map<String, dynamic>?)?[semester];
    return semData == null ? {} : Map<String, String>.from(semData as Map);
  }

  @override
  Future<List<String>> getElectiveYears() async {
    final data = await _fetchJsonData(_electivesUrl);
    return List<String>.from(data.keys);
  }

  @override
  Future<List<String>> getElectiveSemesters(String year) async {
    final data = await _fetchJsonData(_electivesUrl);
    final yearData = data[year] as Map<String, dynamic>?;
    return yearData == null ? [] : List<String>.from(yearData.keys);
  }

  @override
  Future<Map<String, String>?> getElectiveSchemes(
      String year, String semester) async {
    final data = await _fetchJsonData(_electivesUrl);
    final semData = (data[year] as Map<String, dynamic>?)?[semester];
    return semData == null ? null : Map<String, String>.from(semData as Map);
  }
}
