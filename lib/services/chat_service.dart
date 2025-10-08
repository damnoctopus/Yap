import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_room.dart';
import '../models/message.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class ChatService {
  // Get all chats for current user
  static Future<List<ChatRoom>> getChatList() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.BASE_URL}/chats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((chat) => ChatRoom.fromJson(chat)).toList();
      }
      return [];
    } catch (e) {
      print('Error loading chats: $e');
      return [];
    }
  }

  // Get message history
  static Future<List<Message>> getMessages(String chatRoomId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.BASE_URL}/chats/$chatRoomId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((msg) => Message.fromJson(msg)).toList();
      }
      return [];
    } catch (e) {
      print('Error loading messages: $e');
      return [];
    }
  }
}