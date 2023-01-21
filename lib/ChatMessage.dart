// ignore_for_file: public_member_api_docs, sort_constructors_first
enum ChatMessageType { user, bot }

class ChatMessage {
  final String text;
  final ChatMessageType chatMessageType;

  ChatMessage({
    required this.text,
    required this.chatMessageType
  });
}
