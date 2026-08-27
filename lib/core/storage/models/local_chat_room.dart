import 'package:hive/hive.dart';

class LocalChatRoom extends HiveObject {
  String roomId;
  String name;
  String lastMessageText;
  String lastMessageTime;
  int unreadCount;
  bool isAiCoach;

  LocalChatRoom({
    required this.roomId,
    required this.name,
    required this.lastMessageText,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isAiCoach,
  });
}

class LocalChatRoomAdapter extends TypeAdapter<LocalChatRoom> {
  @override
  final int typeId = 1;

  @override
  LocalChatRoom read(BinaryReader reader) {
    return LocalChatRoom(
      roomId: reader.readString(),
      name: reader.readString(),
      lastMessageText: reader.readString(),
      lastMessageTime: reader.readString(),
      unreadCount: reader.readInt(),
      isAiCoach: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, LocalChatRoom obj) {
    writer.writeString(obj.roomId);
    writer.writeString(obj.name);
    writer.writeString(obj.lastMessageText);
    writer.writeString(obj.lastMessageTime);
    writer.writeInt(obj.unreadCount);
    writer.writeBool(obj.isAiCoach);
  }
}
