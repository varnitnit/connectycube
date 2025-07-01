import 'dart:convert';

import 'package:connectycube_flutter_call_kit/connectycube_flutter_call_kit.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:universal_io/io.dart';

import 'package:connectycube_sdk/connectycube_sdk.dart';

import '../../main.dart';
import '../utils/consts.dart';
import '../utils/pref_util.dart';

class PushNotificationsManager {
  static const tag = "PushNotificationsManager";

  static PushNotificationsManager? _instance;

  PushNotificationsManager._internal();

  static PushNotificationsManager _getInstance() {
    return _instance ??= PushNotificationsManager._internal();
  }

  factory PushNotificationsManager() => _getInstance();

  BuildContext? applicationContext;

  static PushNotificationsManager get instance => _getInstance();

  init() async {
    ConnectycubeFlutterCallKit.initEventsHandler();

    ConnectycubeFlutterCallKit.onTokenRefreshed = (token) {
      log('[onTokenRefresh] VoIP token: $token', tag);
      subscribe(token);
    };

    ConnectycubeFlutterCallKit.getToken().then((token) {
      log('[getToken] VoIP token: $token', tag);
      if (token != null) {
        subscribe(token);
      }
    });
    ConnectycubeFlutterCallKit.onCallRejectedWhenTerminated = onCallRejectedWhenTerminated;
    ConnectycubeFlutterCallKit.onCallAcceptedWhenTerminated = onCallAcceptedWhenTerminated;
    ConnectycubeFlutterCallKit.onCallIncomingWhenTerminated = onCallIncomingWhenTerminated;
  }

  subscribe(String token) async {
    log('[subscribe] token: $token', PushNotificationsManager.tag);

    var savedToken = await SharedPrefs.getSubscriptionToken();
    if (token == savedToken) {
      log('[subscribe] skip subscription for same token', PushNotificationsManager.tag);
      // return;
    }

    CreateSubscriptionParameters parameters = CreateSubscriptionParameters();
    parameters.pushToken = token;

    parameters.environment = CubeEnvironment.DEVELOPMENT;
    //parameters.environment = kReleaseMode ? CubeEnvironment.PRODUCTION : CubeEnvironment.DEVELOPMENT;

    if (Platform.isAndroid) {
      parameters.channel = NotificationsChannels.GCM;
      parameters.platform = CubePlatform.ANDROID;
    } else if (Platform.isIOS) {
      parameters.channel = NotificationsChannels.APNS_VOIP;
      parameters.platform = CubePlatform.IOS;
    }

    var deviceInfoPlugin = DeviceInfoPlugin();

    String? deviceId;

    if (kIsWeb) {
      var webBrowserInfo = await deviceInfoPlugin.webBrowserInfo;
      deviceId = base64Encode(utf8.encode(webBrowserInfo.userAgent ?? ''));
    } else if (Platform.isAndroid) {
      var androidInfo = await deviceInfoPlugin.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      var iosInfo = await deviceInfoPlugin.iosInfo;
      deviceId = iosInfo.identifierForVendor;
    } else if (Platform.isMacOS) {
      var macOsInfo = await deviceInfoPlugin.macOsInfo;
      deviceId = macOsInfo.computerName;
    }

    parameters.udid = deviceId;

    var packageInfo = await PackageInfo.fromPlatform();
    parameters.bundleIdentifier = packageInfo.packageName;

    createSubscription(parameters.getRequestParameters()).then((cubeSubscriptions) {
      log('[subscribe] subscription SUCCESS', PushNotificationsManager.tag);
      SharedPrefs.saveSubscriptionToken(token);
      for (var subscription in cubeSubscriptions) {
        if (subscription.clientIdentificationSequence == token) {
          SharedPrefs.saveSubscriptionId(subscription.id!);
        }
      }
    }).catchError((error) {
      log('[subscribe] subscription ERROR: $error', PushNotificationsManager.tag);
    });
  }

  Future<void> unsubscribe() {
    return SharedPrefs.getSubscriptionId().then((subscriptionId) async {
      if (subscriptionId != 0) {
        return deleteSubscription(subscriptionId).then((voidResult) {
          SharedPrefs.saveSubscriptionId(0);
        });
      } else {
        return Future.value();
      }
    }).catchError((onError) {
      log('[unsubscribe] ERROR: $onError', PushNotificationsManager.tag);
    });
  }
}

Future<void> sendPushAboutRejectFromKilledState(
  Map<String, dynamic> parameters,
  int callerId,
) {
  CreateEventParams params = CreateEventParams();
  params.parameters = parameters;
  params.parameters['message'] = "Reject call";
  params.parameters[paramSignalType] = signalTypeRejectCall;
  // params.parameters[PARAM_IOS_VOIP] = 1;

  params.notificationType = NotificationType.PUSH;
  params.environment = CubeEnvironment.DEVELOPMENT;

  //params.environment = !kReleaseMode ? CubeEnvironment.PRODUCTION : CubeEnvironment.DEVELOPMENT;
  params.usersIds = [callerId];

  return createEvent(params.getEventForRequest());
}

@pragma('vm:entry-point')
Future<void> onCallRejectedWhenTerminated(CallEvent callEvent) async {
  log('[PushNotificationsManager][onCallRejectedWhenTerminated] callEvent: $callEvent');

  var currentUser = await SharedPrefs.getUser();
  initConnectycubeContextLess();

  var sendOfflineReject =
      rejectCall(callEvent.sessionId, {...callEvent.opponentsIds.where((userId) => currentUser!.id != userId), callEvent.callerId});
  var sendPushAboutReject = sendPushAboutRejectFromKilledState({
    paramCallType: callEvent.callType,
    paramSessionId: callEvent.sessionId,
    paramCallerId: callEvent.callerId,
    paramCallerName: callEvent.callerName,
    paramCallOpponents: callEvent.opponentsIds.join(','),
  }, callEvent.callerId);

  return Future.wait([sendOfflineReject, sendPushAboutReject]).then((result) {
    return Future.value();
  });
}

///
@pragma('vm:entry-point')
Future<void> onCallIncomingWhenTerminated(CallEvent callEvent) async {
  log('[PushNotificationsManager][onCallIncomingWhenTerminated] callEvent: $callEvent');
  // Initialize ConnectyCube context if needed
  initConnectycubeContextLess();

  // Optionally, you can prepare any background resources or log analytics here.
  // Incoming call notification is already shown by the system via CallKit.
}

@pragma('vm:entry-point')
Future<void> onCallAcceptedWhenTerminated(CallEvent callEvent) async {
  // Log the event for debugging
  log('[PushNotificationsManager][onCallAcceptedWhenTerminated] callEvent: $callEvent');

  // Initialize ConnectyCube context if needed (without UI context)
  initConnectycubeContextLess();

  // Notify backend that the call was accepted (offline handling)
  //await acceptCall(callEvent.sessionId, {...callEvent.opponentsIds, callEvent.callerId});

  // Optionally, send a push notification or update call state as needed
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  initConnectycubeContextLess();
  print(" vvv Handling a background message: ${message.data}");
  ConnectycubeFlutterCallKit.onCallIncomingWhenTerminated = onCallIncomingWhenTerminated;
/*
  final data = message.data;

  // Safely parse message data
  final String sessionId = data['session_id'] ?? '';
  final int callType = int.tryParse(data['call_type'] ?? '') ?? 1;
  final int callerId = int.tryParse(data['caller_id'] ?? '') ?? 0;
  final String callerName = data['caller_name'] ?? 'Unknown';
  final Set<int> opponentsIds = (data['call_opponents'] ?? '')
      .split(',')
      .map((id) => int.tryParse(id.trim()))
      .where((id) => id != null)
      .cast<int>()
      .toSet(); // Convert to Set<int>


  final callEvent = CallEvent(
    sessionId: sessionId,
    callType: callType,
    callerId: callerId,
    callerName: callerName,
    opponentsIds: opponentsIds,
    callPhoto: 'https://i.imgur.com/KwrDil8b.jpg', // Optional placeholder
    userInfo: {'customParameter1': 'value1'},
  );

  ConnectycubeFlutterCallKit.showCallNotification(callEvent);*/
}
