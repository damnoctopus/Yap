import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class AuthService {
  static String? _token;
  static User? _currentUser;

  // Getters
  static String? get token => _token;
  static User? get currentUser => _currentUser;

  //
  static void setMockUser({
    required String id,
    required String name,
    required String username,
    required String token,
  }) {
    _currentUser = User(id: id, name: name, username: username);
    _token = token;
  }

  // Register new user
  static Future<Map<String, dynamic>> register(
      String username,
      String password,
      String name,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.BASE_URL}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _currentUser = User.fromJson(data['user']);

        await _saveToPrefs();

        return {'success': true, 'user': _currentUser};
      } else {
        return {'success': false, 'error': 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login(
      String username,
      String password,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.BASE_URL}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _currentUser = User.fromJson(data['user']);

        await _saveToPrefs();

        return {'success': true, 'user': _currentUser};
      } else {
        return {'success': false, 'error': 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    if (_token != null) return true;

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null) {
      final userId = prefs.getString('userId');
      final userName = prefs.getString('userName');
      final username = prefs.getString('username');

      if (userId != null && userName != null) {
        _currentUser = User(
          id: userId,
          name: userName,
          username: username ?? '',
        );
        return true;
      }
    }

    return false;
  }

  // Logout
  static Future<void> logout() async {
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Save to shared preferences
  static Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('userId', _currentUser!.id);
    await prefs.setString('userName', _currentUser!.name);
    await prefs.setString('username', _currentUser!.username);
  }
}
