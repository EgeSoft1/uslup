// =============================================================================
// TurkiyeMesajlasma - Chat BLoC (State Management)
// Dosya: mobile/lib/presentation/chat/bloc/chat_bloc.dart
//
// Amaç: Akıcı 60 FPS performans için iş mantığını (Business Logic) UI'dan
// tamamen ayırır. Mesaj gönderme eylemi asenkron işlenir: önce veritabanına
// "pending" yazılır, anında UI güncellenir, arka planda şifrelenir ve 
// WebSockets üzerinden yollanır.
// =============================================================================

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

// Domain/Data Servisleri
import '../../../domain/crypto/ffi_bridge.dart';
import '../../../data/local/schema/message.dart';
import '../../../data/repository/chat_repository.dart'; // Isar DB erişimi
import '../../../data/network/websocket_client.dart'; // Axum'a bağlı WS

// --- EVENT'LER ---

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object> get props => [];
}

class LoadMessagesEvent extends ChatEvent {
  final String conversationId;
  const LoadMessagesEvent(this.conversationId);
  @override
  List<Object> get props => [conversationId];
}

class SendMessageEvent extends ChatEvent {
  final String conversationId;
  final String plaintextContent;
  const SendMessageEvent(this.conversationId, this.plaintextContent);
  @override
  List<Object> get props => [conversationId, plaintextContent];
}

class MessageReceivedEvent extends ChatEvent {
  final LocalMessage message;
  const MessageReceivedEvent(this.message);
  @override
  List<Object> get props => [message];
}

// --- STATE'LER ---

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<LocalMessage> messages;
  final bool isTyping; // Karşı taraf yazıyor mu?
  
  const ChatLoaded(this.messages, {this.isTyping = false});
  
  @override
  List<Object?> get props => [messages, isTyping];
  
  ChatLoaded copyWith({List<LocalMessage>? messages, bool? isTyping}) {
    return ChatLoaded(
      messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object> get props => [message];
}

// --- BLOC UYGULAMASI ---

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final WebSocketClient _wsClient;
  final CryptoEngine _cryptoEngine;
  final Uuid _uuid = const Uuid();
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  ChatBloc({
    required ChatRepository chatRepository,
    required WebSocketClient wsClient,
    required CryptoEngine cryptoEngine,
  })  : _chatRepository = chatRepository,
        _wsClient = wsClient,
        _cryptoEngine = cryptoEngine,
        super(ChatInitial()) {
    
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<MessageReceivedEvent>(_onMessageReceived);

    _wsSubscription = _wsClient.onMessageReceived.listen((data) {
      if (data['type'] == 'chat_message') {
        final content = data['content'] as String? ?? '';
        final senderId = data['sender_id'] as String? ?? 'Bilinmeyen';
        
        final msg = LocalMessage()
          ..messageId = _uuid.v4()
          ..conversationId = 'default_conversation'
          ..senderId = senderId
          ..plaintextContent = content
          ..timestamp = DateTime.now()
          ..status = MessageStatus.delivered
          ..hasMedia = false
          ..isDeleted = false
          ..isSelfDestructing = false;
          
        add(MessageReceivedEvent(msg));
      }
    });
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadMessages(LoadMessagesEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      // Isar'dan mesajları anında (O(1) süreyle) çek
      final messages = await _chatRepository.getMessages(event.conversationId);
      emit(ChatLoaded(messages));
    } catch (e) {
      emit(ChatError('Mesajlar yüklenemedi: $e'));
    }
  }

  Future<void> _onSendMessage(SendMessageEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    // 1. O(1) hızında yeni mesaj objesi oluştur ve anında UI'ı (State) güncelle.
    // Zero-lag deneyimi: Kullanıcı mesajın sunucuya gitmesini beklemez.
    final tempId = _uuid.v4(); // TimeUUID client-side üretimi
    final newMessage = LocalMessage()
      ..messageId = tempId
      ..conversationId = event.conversationId
      ..senderId = "BENIM_USER_ID" // Mevcut kullanıcı kimliği (AuthBloc'tan gelir)
      ..plaintextContent = event.plaintextContent
      ..timestamp = DateTime.now()
      ..status = MessageStatus.pending
      ..hasMedia = false
      ..isDeleted = false
      ..isSelfDestructing = false;

    // Listeyi güncelle ve Emit et (UI yenilenir)
    final updatedMessages = List<LocalMessage>.from(currentState.messages)..insert(0, newMessage);
    emit(currentState.copyWith(messages: updatedMessages));

    try {
      // 2. Mesajı Isar'a kaydet (Local DB - Kalıcı Depolama)
      await _chatRepository.saveMessage(newMessage);

      // 3. Mesajı FFI üzerinden Rust Kripto Motoruna gönder
      // Rust arka planda AES-GCM ile şifreler, O(1) allocation.
      // Not: Gerçekte 'sessionId' hedef kullanıcının cihazına aittir.
      final String mockSessionId = "session_${event.conversationId}";
      _cryptoEngine.encryptE2EEMessage(mockSessionId, event.plaintextContent);

      // 4. Şifrelenmiş veriyi Protobuf zarfına (Envelope) yerleştir
      // Protobuf sınıfı (EncryptedEnvelope) pubspec'teki protobuf paketinden generate edilir.
      // Örnek akış:
      // final envelope = EncryptedEnvelope(
      //   ciphertext: encrypted.ciphertext,
      //   nonce: encrypted.nonce,
      //   recipientDeviceId: "HEDEF_CIHAZ_ID",
      // );

      // 5. Axum WebSocket Sunucusuna gönder (Prototip JSON Formatı)
      //
      // DİKKAT: burada DÜZ METİN gönderiliyor — yukarıda üretilen şifreli
      // veri kullanılmıyor. `ffi_bridge.dart` zaten sahte bir motordur
      // (bkz. docs/02_TEKNIK_BORC.md §1). Uçtan uca şifreleme YOKTUR;
      // bu yol faz 2'de gerçek motora bağlanana kadar çağrılmamalıdır.
      _wsClient.sendPayload({
        'type': 'chat_message',
        'sender_id': 'BENIM_USER_ID', // AuthBloc'tan gelecek gerçek ID olmalı
        'content': event.plaintextContent,
      });

      // 6. Mesaj durumunu "Sent" olarak güncelle ve UI'a yansıt
      newMessage.status = MessageStatus.sent;
      await _chatRepository.updateMessageStatus(tempId, MessageStatus.sent);
      
      final reUpdatedMessages = List<LocalMessage>.from(updatedMessages);
      final index = reUpdatedMessages.indexWhere((m) => m.messageId == tempId);
      if (index != -1) {
        reUpdatedMessages[index] = newMessage;
        emit(currentState.copyWith(messages: reUpdatedMessages));
      }

    } catch (e) {
      // Hata anında durum "Failed" olur. (Örn. İnternet yok veya Şifreleme Hatası)
      newMessage.status = MessageStatus.failed;
      await _chatRepository.updateMessageStatus(tempId, MessageStatus.failed);
      
      final failUpdatedMessages = List<LocalMessage>.from(updatedMessages);
      final index = failUpdatedMessages.indexWhere((m) => m.messageId == tempId);
      if (index != -1) {
        failUpdatedMessages[index] = newMessage;
        emit(currentState.copyWith(messages: failUpdatedMessages));
      }
    }
  }

  void _onMessageReceived(MessageReceivedEvent event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final updatedMessages = List<LocalMessage>.from(currentState.messages)..insert(0, event.message);
      emit(currentState.copyWith(messages: updatedMessages));
    }
  }
}
