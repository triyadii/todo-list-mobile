import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/api_config.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('FCM Background message: ${message.messageId}');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  bool _isInitialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Helper to safely get cached token or fetch from Firebase Messaging
  Future<String> getOrFetchFcmToken() async {
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      return _fcmToken!;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _fcmToken = token;
        return token;
      }
    } catch (_) {}
    return '';
  }

  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Initialize Local Notifications Plugin
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (kDebugMode) {
            print('Notification clicked: ${response.payload}');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Local notification init error: $e');
      }
    }

    // 2. Try initialize Firebase & FCM (Push Notifications)
    try {
      if (kIsWeb) {
        // Firebase on Web requires explicit FirebaseOptions
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyDh1WqVArQ4C7cpNMmmqCXDJzQzNiOdjzo',
            appId: '1:330219223368:web:5e184866dbeca800511b7d',
            messagingSenderId: '330219223368',
            projectId: 'mdtnotification',
            storageBucket: 'mdtnotification.firebasestorage.app',
          ),
        );
      } else {
        // On Android / iOS, native configuration is automatically read from google-services.json
        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }

      final messaging = FirebaseMessaging.instance;

      // Request permission (Android 13+ & iOS)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Retrieve FCM Token
        _fcmToken = await messaging.getToken();
        if (_fcmToken != null) {
          if (kDebugMode) {
            print('FCM Token: $_fcmToken');
          }
          await syncFcmTokenWithBackend(_fcmToken!);
        }

        // Listen for token refreshes
        messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          syncFcmTokenWithBackend(newToken);
        });

        // Listen for incoming foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            showNotification(
              title: notification.title ?? 'Smart Todo List',
              body: notification.body ?? '',
              payload: message.data.toString(),
            );
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase not yet configured with google-services.json: $e');
      }
    }

    _isInitialized = true;
  }

  /// Send FCM token to backend user profile
  Future<void> syncFcmTokenWithBackend(String token) async {
    if (!_apiService.isAuthenticated) return;
    try {
      await _apiService.put(
        ApiConfig.userProfile,
        data: {'fcm_token': token},
      );
    } catch (_) {}
  }

  /// Show instant local notification banner
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'todolist_channel_id',
      'Todo List Reminders',
      channelDescription: 'Pengingat aktivitas dan notifikasi Smart Todo List',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}
