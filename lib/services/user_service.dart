import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class UserService
{
  static Future<List<User>> searchUsers(String searchTerm) async
  {
    if (searchTerm.isEmpty) return [];

    try
    {
      final response = await http.get(
        Uri.parse('${Constants.BASE_URL}/users/search?query=$searchTerm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final currentUserId = AuthService.currentUser?.id;
        return data
            .map((userJson) => User.fromJson(userJson))
            .where((user) => user.id != currentUserId)
            .toList();
      }
      else
      {
        print('User search failed with status: ${response.statusCode}');
        return [];
      }
    }
    catch (e)
    {
      print('Error during user search: $e');
      return [];
    }
  }
}