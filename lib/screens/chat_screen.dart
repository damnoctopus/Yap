import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/websocket_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  ChatScreen({required this.chatRoom});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    WebSocketService.onMessageReceived = _handleNewMessage;
  }

  void _loadMessages() async {
    final messages = await ChatService.getMessages(widget.chatRoom.id);
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _handleNewMessage(Message message) {
    final currentUserId = AuthService.currentUser!.id;
    final otherUserId = widget.chatRoom.otherUser.id;
    if (message.senderId == otherUserId && message.receiverId == currentUserId)
    {
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    }
  }

  void _sendMessage()
  {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: AuthService.currentUser!.id,
      receiverId: widget.chatRoom.otherUser.id,
      content: content,
      timestamp: DateTime.now(),
    );

    WebSocketService.sendMessage(message);
    _messageController.clear();

    Future.delayed(Duration(milliseconds:250),() {
      _loadMessages();
    });

  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              child: Text(
                widget.chatRoom.otherUser.name[0].toUpperCase(),
              ),
              radius: 18,
            ),
            SizedBox(width: 10),
            Text(widget.chatRoom.otherUser.name),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
              child: Text(
                'No messages yet\nSay hi! 👋',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message.senderId ==
                    AuthService.currentUser!.id;
                return MessageBubble(
                  message: message,
                  isMe: isMe,
                );
              },
            ),
          ),
          ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}