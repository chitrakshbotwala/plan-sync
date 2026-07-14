import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/campus_navigator/model/campus_navigation_model.dart';

void main() {
  group('CampusNavigationModel.fromJson', () {
    test('maps all fields correctly', () {
      final model = CampusNavigationModel.fromJson({
        'id': 42,
        'title': 'Library',
        'maps_link': 'https://maps.example.com/library',
        'image_path': 'assets/library.png',
      });

      expect(model.id, 42);
      expect(model.title, 'Library');
      expect(model.mapsLink, 'https://maps.example.com/library');
      expect(model.imagePath, 'assets/library.png');
    });

    test('handles null optional fields', () {
      final model = CampusNavigationModel.fromJson({'id': 1});

      expect(model.id, 1);
      expect(model.title, isNull);
      expect(model.mapsLink, isNull);
      expect(model.imagePath, isNull);
    });

    test('id is required and parses from int', () {
      final model = CampusNavigationModel.fromJson({'id': 99});
      expect(model.id, 99);
    });
  });
}
