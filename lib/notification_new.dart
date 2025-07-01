// ignore_for_file: depend_on_referenced_packages, prefer_typing_uninitialized_variables

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class AppNotificationHandler {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
  );

  showNotification(RemoteMessage message) async {
    debugPrint('Notification data: ${message.data}');


    final data = message.data;
    final notificationType = data['type'];

    // Let ConnectyCube handle call notifications
    if (notificationType == 'incoming_call' ||
        data['signal_type'] == 'startCall' ||
        data['ios_voip'] == '1') {
      debugPrint('Received call notification - letting CallKit handle it');
      return; // Let the ConnectyCube CallKit handle this notification
    }

    // For regular notifications, show normal notification
    var android = const AndroidNotificationDetails(
      'channel_general',
      'General Notifications',
      color: Colors.green,
      priority: Priority.high,
      importance: Importance.max,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );
    var iOS = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentBanner: true,
      presentSound: true,
    );
    var platform = NotificationDetails(android: android, iOS: iOS);

    await FlutterLocalNotificationsPlugin().show(
      1,
      message.notification?.title ?? data['title'] ?? 'New Notification',
      message.notification?.body ??
          data['message'] ??
          'You have a new notification',
      platform,
      payload: jsonEncode(data),
    );
  }

  void configureNotifications() {
    // if (Platform.isAndroid) {
    FlutterLocalNotificationsPlugin().initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestCriticalPermission: true,
          requestSoundPermission: true,
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        final data = json.decode(details.payload ?? '{}');

        if (data['type'] == 'incoming_call') {
          // // Navigate to incoming call screen
          // GoRouter.of(AppRouter.navigatorKey.currentState!.context).pushNamed(
          //   AppRouter.callRoute,
          //   extra: {'callerId': "13336036", 'isIncoming': true},
          // );
        }
      },
    );
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      sound: true,
      badge: true,
      alert: true,
    );
  }
}

@pragma('vm:entry-point')
Future onBackgroundMessage(RemoteMessage message) async {
  // if (message.data['groupChatId'] != null) {
  // GoRouter.of(AppRouter.navigatorKey.currentState!.context).pushNamed(
  //   AppRouter.callRoute,
  //   extra: {'callerId': "13336036", 'isIncoming': true},
  // );
  debugPrint("I calllllllllllllllllllll");
  // }
}
