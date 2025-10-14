import 'package:flutter/material.dart';
import '../models/chat_room.dart';
//import '../models/user.dart'; not needed after search feature added
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/websocket_service.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import 'user_search_screen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthService.currentUser != null) {
        WebSocketService.connect();
        WebSocketService.onMessageReceived = _handleNewMessage;
      }
    });
  }

  void _loadChats() async {
    final chats = await ChatService.getChatList();
    setState(() {
      _chatRooms = chats;
      _isLoading = false;
    });
  }

  void _handleNewMessage(message) {
    // reloads all chats when new message is received
    _loadChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _chatRooms.isEmpty
          ? Center(
        child: Text(
          'No chats yet\nStart a new conversation!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _chatRooms.length,
        itemBuilder: (context, index) {
          final chat = _chatRooms[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                chat.otherUser.name[0].toUpperCase(),
              ),
            ),
            title: Text(
              chat.otherUser.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              chat.lastMessage?.content ?? 'No messages',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: chat.unreadCount > 0
                ? Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            )
                : null,
            onTap: () => _openChat(chat),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openSearchScreen,
        backgroundColor: Colors.blue,
        child: Icon(Icons.search),
      ),
    );
  }

  void _openChat(ChatRoom chatRoom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatRoom: chatRoom),
      ),
    ).then((_) => _loadChats());
  }

  void _openSearchScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserSearchScreen()),
    ).then((_) => _loadChats());
  }


  void _handleLogout() async {
    await AuthService.logout();
    WebSocketService.disconnect();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  void dispose() {
    WebSocketService.disconnect();
    super.dispose();
  }
}