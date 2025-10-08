import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/websocket_service.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

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
    WebSocketService.connect();
    WebSocketService.onMessageReceived = _handleNewMessage;
  }

  void _loadChats() async {
    final chats = await ChatService.getChatList();
    setState(() {
      _chatRooms = chats;
      _isLoading = false;
    });
  }

  void _handleNewMessage(message) {
    // Reload chat list when new message arrives
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
              child: Text(
                chat.otherUser.name[0].toUpperCase(),
              ),
              backgroundColor: Colors.blue,
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
        child: Icon(Icons.add),
        onPressed: _showNewChatDialog,
        backgroundColor: Colors.blue,
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

  void _showNewChatDialog() {
    final idController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start New Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: InputDecoration(
                labelText: 'User ID',
                hintText: 'Enter user ID',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'User Name',
                hintText: 'Enter user name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (idController.text.isNotEmpty &&
                  nameController.text.isNotEmpty) {
                final newChat = ChatRoom(
                  id: '${AuthService.currentUser!.id}_${idController.text}',
                  otherUser: User(
                    id: idController.text,
                    name: nameController.text,
                    username: 'user${idController.text}',
                  ),
                );
                Navigator.pop(context);
                _openChat(newChat);
              }
            },
            child: Text('Start Chat'),
          ),
        ],
      ),
    );
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