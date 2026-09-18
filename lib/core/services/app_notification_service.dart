import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Central service for dispatching device-level local notifications.
///
/// Channels:
/// - `quest_uploads`  – video upload progress and completion
/// - `quest_chat`     – chat message alerts
/// - `quest_general`  – quests, level-ups, general updates
class AppNotificationService {
  static final AppNotificationService _instance =
      AppNotificationService._internal();

  factory AppNotificationService() => _instance;
  AppNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Notification Channel IDs ────────────────────────────────────────────
  static const String _uploadChannelId = 'quest_uploads';
  static const String _chatChannelId = 'quest_chat';
  static const String _generalChannelId = 'quest_general';

  // ─── Notification IDs ────────────────────────────────────────────────────
  static const int uploadProgressId = 1;
  static const int uploadCompleteId = 2;
  static const int chatId = 3;
  static const int generalId = 4;

  /// Must be called once during [main] before [runApp].
  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(initSettings);

    // Create Android notification channels
    if (!kIsWeb) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _uploadChannelId,
          'Uploads',
          description: 'Video upload progress and completion alerts',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _chatChannelId,
          'Messages',
          description: 'Incoming chat message alerts',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _generalChannelId,
          'General',
          description: 'Quests, level-ups, and general updates',
          importance: Importance.defaultImportance,
          playSound: false,
        ),
      );

      // Request POST_NOTIFICATIONS permission (Android 13+)
      await androidPlugin?.requestNotificationsPermission();
    }

    _initialized = true;
    debugPrint('[AppNotificationService] Initialized.');
  }

  // ─── Upload Notifications ─────────────────────────────────────────────────

  /// Shows an indeterminate progress notification while uploading.
  Future<void> showUploadProgress(String statusText) async {
    if (!_initialized) return;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _uploadChannelId,
        'Uploads',
        channelDescription: 'Video upload progress',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        showProgress: true,
        maxProgress: 100,
        progress: 0,
        indeterminate: true,
        icon: '@mipmap/ic_launcher',
        ticker: statusText,
      ),
    );
    await _plugin.show(uploadProgressId, 'Quest Upload', statusText, details);
  }

  /// Replaces the progress notification with a completion alert.
  Future<void> showUploadComplete({bool usedFallback = false}) async {
    if (!_initialized) return;
    await _plugin.cancel(uploadProgressId);
    final body = usedFallback
        ? 'Your video is live! (Cloudinary backup)'
        : 'Your video is ready on Quest!';
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _uploadChannelId,
        'Uploads',
        channelDescription: 'Upload complete',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(uploadCompleteId, '🎉 Upload Complete', body, details);
  }

  /// Shows a notification when an upload fails.
  Future<void> showUploadFailed() async {
    if (!_initialized) return;
    await _plugin.cancel(uploadProgressId);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _uploadChannelId,
        'Uploads',
        channelDescription: 'Upload failed',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(
      uploadProgressId,
      '⚠️ Upload Failed',
      'Something went wrong. Please try again.',
      details,
    );
  }

  // ─── Chat Notifications ───────────────────────────────────────────────────

  /// Dispatches a chat message notification.
  Future<void> showChatMessage({
    required String senderName,
    required String preview,
  }) async {
    if (!_initialized) return;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _chatChannelId,
        'Messages',
        channelDescription: 'New message',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(chatId, senderName, preview, details);
  }

  // ─── General Notifications ────────────────────────────────────────────────

  /// Shows a general in-app event notification (quests, level-ups, etc.)
  Future<void> showGeneral({
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _generalChannelId,
        'General',
        channelDescription: 'General updates',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(generalId, title, body, details);
  }

  /// Cancels all active notifications.
  Future<void> cancelAll() => _plugin.cancelAll();
}
