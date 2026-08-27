import 'package:hive/hive.dart';

class LocalChatMessage extends HiveObject {
  String messageId;
  String roomId;
  String text;
  String senderId;
  String createdAt;
  String type;
  bool isPending;

  LocalChatMessage({
    required this.messageId,
    required this.roomId,
    required this.text,
    required this.senderId,
    required this.createdAt,
    required this.type,
    required this.isPending,
  });
}

class LocalChatMessageAdapter extends TypeAdapter<LocalChatMessage> {
  @override
  final int typeId = 2;

  @override
  LocalChatMessage read(BinaryReader reader) {
    return LocalChatMessage(
      messageId: reader.readString(),
      roomId: reader.readString(),
      text: reader.readString(),
      senderId: reader.readString(),
      createdAt: reader.readString(),
      type: reader.readString(),
      isPending: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, LocalChatMessage obj) {
    writer.writeString(obj.messageId);
    writer.writeString(obj.roomId);
    writer.writeString(obj.text);
    writer.writeString(obj.senderId);
    writer.writeString(obj.createdAt);
    writer.writeString(obj.type);
    writer.writeBool(obj.isPending);
  }
}
