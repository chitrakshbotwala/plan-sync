import 'dart:convert';
import 'package:plan_sync/core/services/api_client.dart';
import 'package:plan_sync/features/schedule/repository/sections_repository.dart';
import 'package:plan_sync/util/logger.dart';

class SectionsRepositoryImpl implements SectionsRepository {
  SectionsRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  String get baseUrl =>
      'https://gitlab.com/delwinn/plan-sync/-/raw/${_apiClient.branch}/res';

  String get _sectionsUrl => '$baseUrl/sections.json';
  String get _electivesUrl => '$baseUrl/electives.json';

  Future<Map<String, dynamic>> _fetchSectionsJson() async {
    final response = await _apiClient.dio.get(_sectionsUrl);
    return jsonDecode(response.data) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _fetchElectivesJson() async {
    final response = await _apiClient.dio.get(_electivesUrl);
    return jsonDecode(response.data) as Map<String, dynamic>;
  }

  @override
  Future<List<String>> getYears() async {
    try {
      final data = await _fetchSectionsJson();
      return List<String>.from(data.keys);
    } catch (e) {
      Logger.e('SectionsRepository.getYears failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getSemesters(String year) async {
    try {
      final data = await _fetchSectionsJson();
      final yearData = data[year] as Map<String, dynamic>?;
      return yearData == null ? [] : List<String>.from(yearData.keys);
    } catch (e) {
      Logger.e('SectionsRepository.getSemesters failed: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, String>> getSections(String year, String semester) async {
    try {
      final data = await _fetchSectionsJson();
      final semData = (data[year] as Map<String, dynamic>?)?[semester];
      return semData == null ? {} : Map<String, String>.from(semData as Map);
    } catch (e) {
      Logger.e('SectionsRepository.getSections failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getElectiveYears() async {
    try {
      final data = await _fetchElectivesJson();
      return List<String>.from(data.keys);
    } catch (e) {
      Logger.e('SectionsRepository.getElectiveYears failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getElectiveSemesters(String year) async {
    try {
      final data = await _fetchElectivesJson();
      final yearData = data[year] as Map<String, dynamic>?;
      return yearData == null ? [] : List<String>.from(yearData.keys);
    } catch (e) {
      Logger.e('SectionsRepository.getElectiveSemesters failed: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, String>?> getElectiveSchemes(
      String year, String semester) async {
    try {
      final data = await _fetchElectivesJson();
      final semData = (data[year] as Map<String, dynamic>?)?[semester];
      return semData == null ? null : Map<String, String>.from(semData as Map);
    } catch (e) {
      Logger.e('SectionsRepository.getElectiveSchemes failed: $e');
      rethrow;
    }
  }
}
