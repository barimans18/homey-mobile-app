import 'package:shared_preferences/shared_preferences.dart';

/// Service Local Storage untuk menyimpan sesi autentikasi dan identitas keluarga pengguna
class SessionStorageService {
  static const String _keyIsLoggedIn = 'homey_is_logged_in';
  static const String _keyUserId = 'homey_user_id';
  static const String _keyRole = 'homey_user_role';
  static const String _keyFullName = 'homey_user_full_name';
  static const String _keyFamilyId = 'homey_family_id';
  static const String _keyFamilyName = 'homey_family_name';

  final SharedPreferences _prefs;

  SessionStorageService({required SharedPreferences prefs}) : _prefs = prefs;

  /// Simpan sesi login lokal
  Future<void> saveSession({
    required String userId,
    required String role,
    String? fullName,
    String? familyId,
    String? familyName,
  }) async {
    await _prefs.setBool(_keyIsLoggedIn, true);
    await _prefs.setString(_keyUserId, userId);
    await _prefs.setString(_keyRole, role);
    if (fullName != null && fullName.isNotEmpty) {
      await _prefs.setString(_keyFullName, fullName);
    }
    if (familyId != null && familyId.isNotEmpty) {
      await _prefs.setString(_keyFamilyId, familyId);
    }
    if (familyName != null && familyName.isNotEmpty) {
      await _prefs.setString(_keyFamilyName, familyName);
    }
  }

  /// Cek apakah pengguna sudah pernah login / onboarding
  bool isLoggedIn() {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Ambil data sesi tersimpan
  String? getUserId() => _prefs.getString(_keyUserId);
  String? getRole() => _prefs.getString(_keyRole);
  String? getFullName() => _prefs.getString(_keyFullName);
  String? getFamilyId() => _prefs.getString(_keyFamilyId);
  String? getFamilyName() => _prefs.getString(_keyFamilyName);

  /// Hapus sesi (Logout / Reset)
  Future<void> clearSession() async {
    await _prefs.remove(_keyIsLoggedIn);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyRole);
    await _prefs.remove(_keyFullName);
    await _prefs.remove(_keyFamilyId);
    await _prefs.remove(_keyFamilyName);
  }
}
