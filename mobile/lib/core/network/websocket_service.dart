import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  
  WebSocketService._internal();

  WebSocketChannel? _channel;
  String? _deviceId;
  String? _userId;

  // Gerçek cihazlarda (WiFi üzerinden) test ediyorsanız buraya bilgisayarınızın yerel IP adresini yazın.
  // Örnek: 'ws://192.168.1.55:8080/ws'
  // Android emülatör için genellikle 10.0.2.2 kullanılır.
  final String _wsUrl = 'ws://10.0.2.2:8080/ws';

  bool get isConnected => _channel != null;

  // Gelen mesajları dinlemek için bir stream yayıncısı
  Stream<Map<String, dynamic>>? get messageStream => _channel?.stream.map((event) {
    if (event is String) {
      try {
        return jsonDecode(event) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('WebSocket JSON parse error: $e');
      }
    }
    return {};
  });

  void connect() {
    if (_channel != null) return;
    
    try {
      debugPrint('Connecting to WebSocket at $_wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      
      _userId = const Uuid().v4();
      _deviceId = const Uuid().v4();

      // Bağlantı sonrası ilk kimlik bilgisini (Auth) gönder (Prototip için)
      sendMessage({
        'type': 'auth',
        'user_id': _userId,
        'device_id': _deviceId,
      });
      
      debugPrint('WebSocket Connected!');
    } catch (e) {
      debugPrint('WebSocket Connection Error: $e');
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    debugPrint('WebSocket Disconnected');
  }

  void sendMessage(Map<String, dynamic> data) {
    if (_channel != null) {
      final jsonString = jsonEncode(data);
      _channel!.sink.add(jsonString);
      debugPrint('WS Sent: $jsonString');
    } else {
      debugPrint('Cannot send message, WS not connected.');
    }
  }

  void sendChatMessage(String text) {
    sendMessage({
      'type': 'chat_message',
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
