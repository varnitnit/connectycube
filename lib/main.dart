import 'package:connectycube_flutter_call_kit/connectycube_flutter_call_kit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:connectycube_sdk/connectycube_sdk.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:p2p_call_sample/src/managers/push_notifications_manager.dart';
import 'package:p2p_call_sample/src/utils/consts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'firebase_options.dart';
import 'notification_new.dart';
import 'notification_services.dart';
import 'src/config.dart' as config;
import 'src/login_screen.dart';
import 'src/utils/pref_util.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_channel', // id
    'Notifications', // title
    // 'This channel is used for important notifications.', // description
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('assets/sound/audio_dummy.wav'));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Request permissions
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  AppNotificationHandler().configureNotifications();

  // request permissions for showing notification in iOS

  firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);

  // add listener for foreground push notifications
  FirebaseMessaging.onMessage.listen((remoteMessage) {
    log('[onMessage] message: $remoteMessage');
    //  showNotification(remoteMessage);
  });

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(NotificationService.channel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  NotificationService.getInitialMsg();
  // Update the iOS foreground notification presentation options to allow
  // heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: false,
    sound: true,
  );
  NotificationService.showMsgHandler();
 // NotificationService.getFCMToken();
  await [
    Permission.microphone,
    Permission.notification,
  ].request();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const App());
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AppState();
  }
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: Builder(
        builder: (context) {
          return const LoginScreen();
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    ConnectycubeFlutterCallKit.instance.init();

    initConnectycube();
  }
}

initConnectycube() {
  init(
    config.appId,
    config.authKey,
    '',
    onSessionRestore: () {
      return SharedPrefs.getUser().then((savedUser) {
        return createSession(savedUser);
      });
    },
  );
  setEndpoints(config.apiEndpoint, config.chatEndpoint);
}

initConnectycubeContextLess() {
  CubeSettings.instance.applicationId = config.appId;
  CubeSettings.instance.authorizationKey = config.authKey;
  CubeSettings.instance.onSessionRestore = () {
    return SharedPrefs.getUser().then((savedUser) {
      return createSession(savedUser);
    });
  };

  setEndpoints(config.apiEndpoint, config.chatEndpoint);
}
