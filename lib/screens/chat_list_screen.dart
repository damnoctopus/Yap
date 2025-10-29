import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/websocket_service.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import 'user_search_screen.dart';

// --- Theme Constants for a Modern Look ---
const Color kPrimaryColor = Color(0xFF5E64FF); // A vibrant, modern blue/purple
const Color kAccentColor = Color(0xFFFFC700); // A bright accent for flair
const Color kBackgroundColor = Color(0xFFF7F7F7); // Light background for contrast
const Color kTextColor = Color(0xFF333333); // Dark text for readability
const Color kSubtitleColor = Color(0xFF888888); // Grey for secondary text

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
        // Ensure this is only set once to avoid duplicate listeners if screen rebuilds
        if (WebSocketService.onMessageReceived == null) {
          WebSocketService.onMessageReceived = _handleNewMessage;
        }
      }
    });
  }

  void _loadChats() async {
    // Simulate a slight delay for a smoother loading transition
    await Future.delayed(Duration(milliseconds: 100));
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
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kPrimaryColor,
        elevation: 0, // Flat app bar for a cleaner look
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _chatRooms.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: kSubtitleColor),
            SizedBox(height: 20),
            Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the search button to start a new conversation!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: kSubtitleColor),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.only(top: 8),
        itemCount: _chatRooms.length,
        itemBuilder: (context, index) {
          final chat = _chatRooms[index];
          return _buildChatListItem(chat);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openSearchScreen,
        backgroundColor: kAccentColor, // Use accent color for Floating Action Button
        child: Icon(Icons.search, color: kTextColor),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      ),
    );
  }

  Widget _buildChatListItem(ChatRoom chat) {
    // Enhanced ListTile with better padding, colors, and typography
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: kPrimaryColor.withOpacity(0.15), // Lighter background
          child: Text(
            chat.otherUser.name[0].toUpperCase(),
            style: TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            chat.otherUser.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: kTextColor,
              fontSize: 17,
            ),
          ),
        ),
        subtitle: Text(
          chat.lastMessage?.content ?? 'Start chatting!',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: kSubtitleColor,
            fontSize: 14,
          ),
        ),
        trailing: chat.unreadCount > 0
            ? Container(
          padding: EdgeInsets.all(8),
          constraints: BoxConstraints(minWidth: 30),
          decoration: BoxDecoration(
            color: kAccentColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              chat.unreadCount.toString(),
              style: TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        )
            : null,
        onTap: () => _openChat(chat),
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
    // Use pushAndRemoveUntil to clear the navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    // Only disconnect if we are navigating away from the app completely
    // If you only want to disconnect on logout, keep it in _handleLogout
    // I'll keep it here as it was in the original code, but note the alternative above.
    // If the widget is being disposed and not just swapped in the stack, we disconnect.
    // However, the logout handles navigation away.
    // A more robust app might only disconnect on logout for better experience.
    // For now, I'll remove the disconnect from dispose to avoid issues if the screen is
    // merely popped for a moment, as logout handles the final disconnect.
    // The original code had it, so I'll put it back for functional parity:
    WebSocketService.disconnect();
    super.dispose();
  }
}