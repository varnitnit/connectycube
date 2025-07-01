/*
// ignore_for_file: unused_element, use_build_context_synchronously, unnecessary_null_comparison, deprecated_member_use
import 'package:app_links/app_links.dart';
import 'package:connectycube_flutter_call_kit/connectycube_flutter_call_kit.dart';
import 'package:connectycube_sdk/connectycube_sdk.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mh_ride/core/colors/app_colors.dart';
import 'package:mh_ride/core/constants/api_urls.dart';
import 'package:mh_ride/core/main/app_provider.dart';
import 'package:mh_ride/core/main/localization_app.dart';
import 'package:mh_ride/core/router/routes.dart';
import 'package:mh_ride/data/repositoies/chat_repository.dart';
import 'package:mh_ride/presentation/screens/home/cubit/trip_status/trip_status_cubit.dart';
import 'package:mh_ride/presentation/widgets/talker_log.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talker/talker.dart';
import 'notification.dart';
import 'options/firebase_options.dart';
import 'dart:async';

Talker talker = Talker();
late final AppLinks _appLinks;

final FlutterLocalNotificationsPlugin _notifications =
FlutterLocalNotificationsPlugin();

Future<void> initCubeSDK() async {
  // Initialize the ConnectyCube SDK with your credentials
  init(APP_IDD, AUTH_KEYY, AUTH_SECRETT);
  showLog("KEYS VALUE :: $APP_IDD, $AUTH_KEYY, $AUTH_SECRETT");
  CubeSettings.instance.isDebugEnabled = true;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);

  FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
  AppNotificationHandler().configureNotifications();
  await initCubeSDK();
  // _initDependencies();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getApplicationDocumentsDirectory(),
  );
  final chatRepository = ChatRepository();
  await chatRepository.initCallKit();

  // Register background call handlers
  ConnectycubeFlutterCallKit.onCallAcceptedWhenTerminated =
      onCallAcceptedWhenTerminated;
  ConnectycubeFlutterCallKit.onCallRejectedWhenTerminated =
      onCallRejectedWhenTerminated;
  ConnectycubeFlutterCallKit.onCallIncomingWhenTerminated =
      onCallIncomingWhenTerminated;

  //payment gateway
  Stripe.publishableKey = STRIPE_PUBLISHABLE_KEY;
  Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
  Stripe.urlScheme = 'flutterstripe';
  await Stripe.instance.applySettings();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: whiteColor,
      systemNavigationBarColor: blackColor,
      systemNavigationBarIconBrightness: Brightness.dark));

  init(APP_IDD, AUTH_KEYY, AUTH_SECRETT);
  CubeSettings.instance.isDebugEnabled = true;
  _appLinks = AppLinks();

  _appLinks.uriLinkStream.listen((uri) {
    debugPrint("Uri====$uri");
    if (uri != null) {
      debugPrint("Call Api???");
      final state = BlocProvider.of<TripStatusCubit>(
          AppRouter.navigatorKey.currentState!.context)
          .state;
      if (state is TripStatusSuccess) {
        if (state.response.tripStatus == "approved" ||
            state.response.tripStatus == "enroute_to_customer" ||
            state.response.tripStatus == "reached_to_customer" ||
            state.response.tripStatus == "customer_on_board") {
          GoRouter.of(AppRouter.navigatorKey.currentState!.context)
              .push(AppRouter.riderDetailsRoute, extra: {
            'initialDriverLat': state.response.travelingTrip.driverDetails
                .driverLocations.actualLocation.lat,
            'initialDriverLng': state.response.travelingTrip.driverDetails
                .driverLocations.actualLocation.lng,
          });
        }
      }
    }
  });

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then(
        (_) async {
      debugPrint("INto main==================");
      runApp(
        AppProviders.provideApp(
          const LocalizationApp(),
        ),
      );
    },
  );
}

@pragma('vm:entry-point')
Future<void> onCallAcceptedWhenTerminated(CallEvent callEvent) async {
  await initCubeSDK();

  showLog('Call accepted in terminated state: ${callEvent.sessionId}');
}

@pragma('vm:entry-point')
Future<void> onCallRejectedWhenTerminated(CallEvent callEvent) async {
  await initCubeSDK();

  showLog('Call rejected in terminated state: ${callEvent.sessionId}');
}

@pragma('vm:entry-point')
Future<void> onCallIncomingWhenTerminated(CallEvent callEvent) async {
  await initCubeSDK();

  showLog('Call incoming in terminated state: ${callEvent.sessionId}');
}

*/
