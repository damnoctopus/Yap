import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/chat_room.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class UserSearchScreen extends StatefulWidget
{
  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen>
{
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isLoading = false;
  String _lastQuery = '';

  void _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || query == _lastQuery) return;

    setState(() {
      _isLoading = true;
      _searchResults = [];
      _lastQuery = query;
    });

    final results = await UserService.searchUsers(query);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  void _openChatWithUser(User user) {

    final currentUserId = AuthService.currentUser!.id;
    final otherUserId = user.id;
    final chatRoomId = [currentUserId, otherUserId].join('_');
    final newChatRoom = ChatRoom(
      id: chatRoomId,
      otherUser: user,
    );

    Navigator.pop(context, true);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatRoom: newChatRoom),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find User'),
        backgroundColor: Colors.blue,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or username...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: Colors.white),
                  onPressed: _search,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white24,
                contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 0),
              ),
              style: TextStyle(color: Colors.white),
              onSubmitted: (_) => _search(),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty && _lastQuery.isNotEmpty
          ? Center(
        child: Text('No users found for "$_lastQuery"'),
      )
          : _searchResults.isEmpty && _lastQuery.isEmpty
          ? Center(
        child: Text('Enter a name or username to start searching.'),
      )
          : ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(user.name[0].toUpperCase()),
            ),
            title: Text(user.name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('@${user.username}'),
            onTap: () => _openChatWithUser(user),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}