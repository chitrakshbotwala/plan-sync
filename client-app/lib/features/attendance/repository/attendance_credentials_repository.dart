/// Storage contract for the student's KIIT portal credentials.
///
/// Credentials are held in the platform keystore — only the registration
/// number is cached in memory (for display); the password is read on demand.
abstract class AttendanceCredentialsRepository {
  /// Loads the registration number from the keystore into memory.
  /// Call once at app startup before reading [registrationNumber].
  Future<void> initialize();

  /// The cached registration number, or null if no credentials are stored.
  String? get registrationNumber;

  bool get hasCredentials;

  /// Returns `(registrationNumber, password)` or `null` if either is missing.
  Future<(String, String)?> read();

  Future<void> save({
    required String registrationNumber,
    required String password,
  });

  Future<void> clear();
}
