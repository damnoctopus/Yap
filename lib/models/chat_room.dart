import 'package:chat_app/models/user.dart';
import 'package:chat_app/models/message.dart';

class ChatRoom {
  final String id;
  final User otherUser;
  final Message? lastMessage;
  final int unreadCount;

  ChatRoom({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      otherUser: User.fromJson(json['otherUser']),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}