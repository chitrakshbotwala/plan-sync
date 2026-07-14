import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:plan_sync/features/attendance/repository/attendance_credentials_repository.dart';

class AttendanceCredentialsRepositoryImpl
    implements AttendanceCredentialsRepository {
  static const _registrationKey = 'kiit_registration_number';
  static const _passwordKey = 'kiit_password';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _registrationNumber;

  @override
  String? get registrationNumber => _registrationNumber;

  @override
  bool get hasCredentials =>
      _registrationNumber != null && _registrationNumber!.isNotEmpty;

  @override
  Future<void> initialize() async {
    try {
      _registrationNumber = await _storage.read(key: _registrationKey);
    } catch (e) {
      // A corrupt keystore entry shouldn't crash app start; treat as "not set".
      debugPrint('[attendance] failed to read stored credentials: $e');
      _registrationNumber = null;
    }
  }

  @override
  Future<(String, String)?> read() async {
    try {
      final reg = await _storage.read(key: _registrationKey);
      final pass = await _storage.read(key: _passwordKey);
      if (reg == null || reg.isEmpty || pass == null || pass.isEmpty) {
        return null;
      }
      return (reg, pass);
    } catch (e) {
      debugPrint('[attendance] failed to read stored credentials: $e');
      return null;
    }
  }

  @override
  Future<void> save({
    required String registrationNumber,
    required String password,
  }) async {
    final reg = registrationNumber.trim();
    await _storage.write(key: _registrationKey, value: reg);
    await _storage.write(key: _passwordKey, value: password);
    _registrationNumber = reg;
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _registrationKey);
    await _storage.delete(key: _passwordKey);
    _registrationNumber = null;
  }
}
