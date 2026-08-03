import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Gateway ile WebSocket bağlantısı.
///
/// NOT: Rust ağ geçidi bu teslimatta kapsam dışıdır (`docs/02_TEKNIK_BORC.md`
/// §5). Bu sınıf faz 2 için hazır tutulur; şu an hiçbir ekran çağırmaz.
class WebSocketClient {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _disposed = false;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onMessageReceived =>
      _messageController.stream;

  /// Yeniden bağlanma gecikmesi. Sabit 3 sn yerine üstel geri çekilme:
  /// sunucu kapalıyken saniyede bir bağlanmaya çalışmak hem pili hem
  /// sunucuyu boşuna yorar.
  int _attempt = 0;
  Duration get _backoff =>
      Duration(seconds: (1 << _attempt.clamp(0, 5)).clamp(1, 32));

  void connect(String token) {
    if (_disposed) return;
    _reconnectTimer?.cancel();

    // 10.0.2.2, Android emülatöründe ana makinenin localhost'udur.
    final wsUrl = Uri.parse('ws://10.0.2.2:8080/ws?token=$token');

    try {
      _channel = WebSocketChannel.connect(wsUrl);
      _log('bağlanıyor → $wsUrl');

      _channel?.sink.add(jsonEncode({'type': 'auth', 'token': token}));

      // Önceki aboneliği bırakmadan yenisini açmak, kopan her bağlantıda
      // dinleyici biriktiriyordu — her mesaj birden çok kez işleniyordu.
      _subscription?.cancel();
      _subscription = _channel?.stream.listen(
        (data) {
          _attempt = 0;
          try {
            final decoded = jsonDecode(data as String);
            if (decoded is Map<String, dynamic>) {
              _messageController.add(decoded);
            }
          } catch (e) {
            _log('çözümleme hatası: $e');
          }
        },
        onDone: () {
          _log('bağlantı kapandı');
          _scheduleReconnect(token);
        },
        onError: (Object error) {
          _log('hata: $error');
          _scheduleReconnect(token);
        },
        cancelOnError: true,
      );
    } catch (e) {
      _log('bağlantı kurulamadı: $e');
      _scheduleReconnect(token);
    }
  }

  void _scheduleReconnect(String token) {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    final delay = _backoff;
    _attempt++;
    _log('${delay.inSeconds} sn sonra yeniden denenecek');
    _reconnectTimer = Timer(delay, () => connect(token));
  }

  void sendPayload(Map<String, dynamic> data) {
    final channel = _channel;
    if (channel == null) {
      _log('gönderilemedi: kanal açık değil');
      return;
    }
    channel.sink.add(jsonEncode(data));
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _log('bağlantı kesildi');
  }

  /// Kaynakları bırakır. Bu çağrılmadığı için `StreamController` sızıyordu.
  void dispose() {
    _disposed = true;
    disconnect();
    _messageController.close();
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[WebSocket] $message');
  }
}
