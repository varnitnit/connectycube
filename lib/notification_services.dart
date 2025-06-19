import 'dart:convert';
import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    importance: Importance.high,
  );
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  static getFCMToken() async {
    log('hello...');
    try {
      String? token = await FirebaseMessaging.instance.getToken();

      log('token>> ${token}');
    } catch (e) {
      log('eeee>> $e');
    }
  }

  static Future<void> showMsgHandler() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    const InitializationSettings initialSettings = InitializationSettings(
        android: AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ),
        iOS: DarwinInitializationSettings());

    FirebaseMessaging.onMessage.listen((RemoteMessage? message) {
      RemoteNotification? notification = message?.notification;

      showMsg(notification, message);
      flutterLocalNotificationsPlugin.initialize(initialSettings, onDidReceiveNotificationResponse: (NotificationResponse details) {
        print('details.payload>>>>>> ${details.payload}');
      });
    });
  }

  /// handle notification when app in fore ground..///close app
  static void getInitialMsg() {
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      log('------RemoteMessage message------$message');
    });
  }

  ///show notification msg
  static void showMsg(RemoteNotification? notification, RemoteMessage? message) {
    if (notification?.android != null) {
      flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          '${notification?.title}',
          '${notification?.body}',
          const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel', // id
                'High Importance Notifications', // title
                //'This channel is used for important notifications.',
                // description
                importance: Importance.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true)),
          payload: jsonEncode(message?.data));
    }
  }

  ///background notification handler..
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();

    log('Handling a background message ${message.data}');
    RemoteNotification? notification = message.notification;

    const InitializationSettings initialSettings = InitializationSettings(
        android: AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ),
        iOS: DarwinInitializationSettings());

    flutterLocalNotificationsPlugin.initialize(initialSettings, onDidReceiveNotificationResponse: (NotificationResponse details) {
      print('details.payload>>>>>> ${details.payload}');

      var data = jsonDecode('${details.payload}');
      print('SUITOR IDDDIDIDIDI>>>>  ${data['suitorId']}');
      print('SUITOR TYPESS>>>>  ${data['type']}');
    });
  }

  ///call when click on notification back
  static void onMsgOpen() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('A new onMessageOpenedApp event was published!');
      log('listen->${message.data}');

      log('WHAT IS COMING DATA   ${message.data}');
      log('WHAT IS Types   ${message.data['type']}');
    });
  }
}
