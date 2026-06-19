abstract class SectionsRepository {
  Stream<List<String>> getYears();
  Stream<List<String>> getSemesters(String year);
  Stream<Map<String, String>> getSections(String year, String semester);

  Stream<List<String>> getElectiveYears();
  Stream<List<String>> getElectiveSemesters(String year);
  Stream<Map<String, String>?> getElectiveSchemes(String year, String semester);
}
