abstract class SectionsRepository {
  Future<List<String>> getYears();
  Future<List<String>> getSemesters(String year);
  Future<Map<String, String>> getSections(String year, String semester);

  Future<List<String>> getElectiveYears();
  Future<List<String>> getElectiveSemesters(String year);
  Future<Map<String, String>?> getElectiveSchemes(String year, String semester);
}
