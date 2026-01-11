import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription? _userDocSubscription;
  
  // YENİ: O an hangi chat odasındayız?
  static String? activeRoomId;

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(android: androidInit);
      await _localNotifications.initialize(initSettings);

      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          _updateUserToken(user.uid);
          _listenToUserProfile(user.uid);
        } else {
          _userDocSubscription?.cancel();
        }
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showNotification(
          message.notification?.title ?? 'Vroomy',
          message.notification?.body ?? 'Yeni bir bildiriminiz var!',
        );
      });
    }
  }

  void _listenToUserProfile(String uid) {
    _userDocSubscription?.cancel();
    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final String? lastNotif = data?['lastNotification'];
        final int unreadCount = data?['unreadCount'] ?? 0;
        final String? notifRoomId = data?['lastNotificationRoomId']; // Yeni alan

        // KRİTİK FİLTRE: 
        // 1. Okunmamış mesaj varsa
        // 2. Mesaj içeriği boş değilse
        // 3. Kullanıcı O AN o sohbet odasında DEĞİLSE bildirim göster
        if (unreadCount > 0 && lastNotif != null) {
          if (activeRoomId == null || activeRoomId != notifRoomId) {
            _showNotification('Vroomy', lastNotif);
          }
        }
      }
    });
  }

  Future<void> _updateUserToken(String uid) async {
    String? token = await _fcm.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }

  void _showNotification(String title, String body) {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vroomy_chat_channel',
      'Vroomy Mesajlar',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
    );
  }
}
