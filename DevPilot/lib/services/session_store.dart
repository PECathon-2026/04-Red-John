import 'package:shared_preferences/shared_preferences.dart';

/// Persists the signed-in session (bearer token + backend URL) across app launches.
///
/// Every call swallows platform errors so widget tests and unsupported
/// platforms simply behave as "nothing saved".
class SessionStore {
  static const _tokenKey = 'devpilot_access_token';
  static const _baseUrlKey = 'devpilot_backend_url';

  const SessionStore();

  Future<String?> readToken() => _read(_tokenKey);
  Future<void> writeToken(String? token) => _write(_tokenKey, token);

  Future<String?> readBaseUrl() => _read(_baseUrlKey);
  Future<void> writeBaseUrl(String? url) => _write(_baseUrlKey, url);

  Future<String?> _read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, String? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null || value.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value);
      }
    } catch (_) {}
  }
}
