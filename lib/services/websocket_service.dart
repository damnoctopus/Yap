import 'dart:convert';
import '../models/message.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart'; // The correct, single entry point

class WebSocketService {
  static StompClient? _stompClient;
  static Function(Message)? onMessageReceived;

  static void connect() {
    final currentUserId = AuthService.currentUser?.id;

    if (currentUserId == null) {
      print('Error: Cannot connect, user ID is missing.');
      return;
    }

    // Initialize StompClient with SockJS configuration
    _stompClient = StompClient(
      // CRITICAL FIX: Use the HTTP URL for StompConfig.sockJS
      // The SockJS constructor adds the necessary /ws/session_id pathing internally.
      config: StompConfig.sockJS(
        url: Constants.SOCKJS_URL, // Use the new HTTP URL
        // The rest of your configuration (onConnect, error handling) remains the same
        onConnect: (StompFrame frame) {
          print('STOMP connected for user $currentUserId');

          // CRITICAL FIX: SUBSCRIBE to the personal topic
          _stompClient!.subscribe(
            destination: '/topic/messages/$currentUserId',
            callback: (StompFrame frame) {
              try {
                final message = Message.fromJson(jsonDecode(frame.body!));
                onMessageReceived?.call(message);
              } catch (e) {
                print('Error parsing received message: $e');
              }
            },
          );
        },
        onWebSocketError: (error) => print('WebSocket error: $error'),
        onStompError: (StompFrame frame) => print('STOMP error: ${frame.body}'),
        onDisconnect: (frame) => print('STOMP disconnected'),
      ),
    );

    // Start the connection process
    _stompClient!.activate();
    print('STOMP connection logic initialized for user: $currentUserId');
  }

  static void sendMessage(Message message) {
    if (_stompClient != null && _stompClient!.connected)
    {
      final payload = {
        'senderId': message.senderId,
        'receiverId': message.receiverId,
        'content': message.content,
      };

      _stompClient!.send(
        destination: '/app/chat.send',
        body: jsonEncode(payload),
        headers: {'content-type': 'application/json'},
      );
    } else {
      print('STOMP client is not connected. Message not sent.');
    }
  }

  static void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
    print('STOMP client disconnected');
  }
}