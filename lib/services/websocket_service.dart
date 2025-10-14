import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message.dart';
import '../utils/constants.dart';

class WebSocketService {
  static WebSocketChannel? _channel;
  static Function(Message)? onMessageReceived;

  // Connect to WebSocket
  static void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(Constants.WS_URL));

      _channel!.stream.listen(
            (data) {
          try {
            final message = Message.fromJson(jsonDecode(data));
            onMessageReceived?.call(message);
          } catch (e) {
            print('Error parsing message: $e');
          }
        },
        onError: (error) => print('WebSocket error: $error'),
        onDone: () => print('WebSocket closed'),
      );
    } catch (e) {
      print('Error connecting to WebSocket: $e');
    }
  }

  // Send message
  static void sendMessage(Message message) {
    if (_channel != null) {
      final data = {
        // Send IDs as strings to prevent loss of precision or type mismatch
        'senderId': message.senderId,      // KEEP AS STRING
        'receiverId': message.receiverId,  // KEEP AS STRING
        'content': message.content,
      };
      _channel!.sink.add(jsonEncode(data));
    }
  }

  // Disconnect
  static void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}