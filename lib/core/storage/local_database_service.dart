import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quest/core/storage/models/local_chat_room.dart';
import 'package:quest/core/storage/models/local_chat_message.dart';

final localDatabaseProvider = Provider<LocalDatabaseService>((ref) {
  throw UnimplementedError(
    'localDatabaseProvider must be overridden in ProviderScope',
  );
});

class LocalDatabaseService {
  late Box<LocalChatRoom> chatRoomsBox;
  late Box<LocalChatMessage> chatMessagesBox;

  Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(LocalChatRoomAdapter());
    Hive.registerAdapter(LocalChatMessageAdapter());

    chatRoomsBox = await Hive.openBox<LocalChatRoom>('chat_rooms');
    chatMessagesBox = await Hive.openBox<LocalChatMessage>('chat_messages');
  }
}
