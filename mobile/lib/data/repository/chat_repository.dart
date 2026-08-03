import '../local/schema/message.dart';

class ChatRepository {
  final List<LocalMessage> _messages = [];

  Future<List<LocalMessage>> getMessages(String conversationId) async {
    return _messages.where((m) => m.conversationId == conversationId).toList().reversed.toList();
  }

  Future<void> saveMessage(LocalMessage message) async {
    _messages.add(message);
  }

  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final index = _messages.indexWhere((m) => m.messageId == messageId);
    if (index != -1) {
      _messages[index].status = status;
    }
  }
}
