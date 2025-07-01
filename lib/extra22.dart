/*
// ignore_for_file: unused_element, use_build_context_synchronously

import 'package:connectycube_flutter_call_kit/connectycube_flutter_call_kit.dart';
import 'package:connectycube_sdk/connectycube_sdk.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mh_ride/core/constants/hydrate_constant.dart';
import 'package:mh_ride/core/constants/text_style.dart';
import 'package:mh_ride/core/router/routes.dart';
import 'package:mh_ride/presentation/screens/call/call_screen.dart';
import 'package:mh_ride/presentation/widgets/talker_log.dart';

class ChatRepository {
  List<CubeDialog> dialogsList = [];
  Map<String, List<CubeMessage>> messagesByDialog = {};
  P2PClient? _callClient;
  bool _isInitialized = false;
  P2PSession? activeCallSession;

  Future<void> initCallKit() async {
    showLog('initCallKit initialized successfully');
    try {
      // Initialize call kit with handlers
      ConnectycubeFlutterCallKit.instance.init(
        onCallAccepted: _onCallAccepted,
        onCallRejected: _onCallRejected,
        onCallIncoming: _onCallIncoming,
      );

      showLog('ConnectyCube Call Kit initialized successfully');
      // Set app-specific call kit configuration
      await ConnectycubeFlutterCallKit.instance.updateConfig(
        ringtone:
        'ringtone', // Android: use filename in res/raw, iOS: use system sound name
        icon: 'app_icon', // Image in drawable folder
        color: '#E91E63', // Notification color
      );

      await initCallClient();

      listenForIncomingCalls(
        onIncomingCall: (session) {
          // Handle UI update or navigation to call screen if needed
          showLog('Incoming call received from: ${session.callerId}');
        },
        onCallSessionClosed: (session) {
          // Handle UI teardown or cleanup
          showLog('Call session closed: ${session.sessionId}');
        },
      );
      // Check for any pending calls when app starts (from terminated state)
      String? lastCallId = await ConnectycubeFlutterCallKit.getLastCallId();
      if (lastCallId != null) {
        showLog('Found pending call: $lastCallId');
        // Handle reopening to the correct call screen
      }

      showLog('ConnectyCube Call Kit initialized successfully');
    } catch (e) {
      showLog('Error initializing ConnectyCube Call Kit: $e');
    }
  }

  // Handler for when a call is accepted via notification
  Future<void> _onCallAccepted(CallEvent callEvent) async {
    showLog('Call accepted from notification: ${callEvent.sessionId}');

    // Ensure call client is initialized
    // if (!_isInitialized) {
    await initCallClient();
    //}
    debugPrint("Session Id========$activeCallSession");
    // Find the call session if it exists, otherwise we'll create a new one
    if (activeCallSession != null &&
        activeCallSession!.sessionId == callEvent.sessionId) {
      acceptCall(activeCallSession!);
    }

    // Navigate to call screen
    if (AppRouter.navigatorKey.currentContext != null) {
      Navigator.of(
        AppRouter.navigatorKey.currentContext!,
        rootNavigator: true,
      ).push(
        MaterialPageRoute(
          builder: (context) => CallScreen(
            callerId: callEvent.callerId.toString(),
            isIncoming: true,
          ),
        ),
      );
    }
  }

  // Handler for when a call is rejected via notification
  Future<void> _onCallRejected(CallEvent callEvent) async {
    showLog('Call rejected from notification: ${callEvent.sessionId}');

    // Ensure call client is initialized
    // if (!_isInitialized) {
    await initCallClient();
    // }

    // Find the call session and reject it
    if (activeCallSession != null &&
        activeCallSession!.sessionId == callEvent.sessionId) {
      rejectCall(activeCallSession!);
      activeCallSession = null;
    }
  }

  // Handler for when a call is muted via notification
  void _onCallMuted(bool muted, String sessionId) {
    showLog('Call muted from notification: muted=$muted, sessionId=$sessionId');

    // Find the call session and toggle mute
    if (activeCallSession != null &&
        activeCallSession!.sessionId == sessionId) {
      toggleMute(activeCallSession!, muted);
    }
  }

  // Handler for an incoming call event
  Future<void> _onCallIncoming(CallEvent callEvent) async {
    showLog('New incoming call: ${callEvent.sessionId}');
    // Handle any application-specific logic for incoming calls
    // This is called when a call notification is received
    CreateEventParams params = CreateEventParams();
    params.parameters = {
      'message': "Incoming Audio call",
      'call_type': CallType.AUDIO_CALL,
      'session_id': callEvent.sessionId,
      'caller_id': callEvent.callerId,
      'caller_name': callEvent.callerName,
      'call_opponents': callEvent.opponentsIds.join(','),
      'photo_url': 'https://i.imgur.com/KwrDil8b.jpg',
      'signal_type': 'startCall',
      'ios_voip': 1,
    };

    params.notificationType = NotificationType.PUSH;
    params.environment = CubeEnvironment.DEVELOPMENT; // not important
    params.usersIds = callEvent.opponentsIds.toList();

    createEvent(params.getEventForRequest()).then((cubeEvent) {
      // event was created
    }).catchError((error) {
      // something went wrong during event creation
    });
  }

  Future<void> initCallClient() async {
    if (!_isInitialized) {
      try {
        // Make sure we have an active session
        CubeSession? session = await getActiveSession();
        if (session == null || session.user == null) {
          showLog('No active session found - logging in');
          final userId =
          HydratedBloc.storage.read(HydrateConstant.connectyCubeId);
          final email =
          HydratedBloc.storage.read(HydrateConstant.customerEmail);

          showLog("sessionn :: $userId, $email");
          if (userId != null && email != null) {
            CubeUser user = CubeUser()
              ..id = int.tryParse(userId.toString())
              ..email = email
              ..password = '1234567890';

            showLog("CALL :: $email");

            if (session == null) {
              await createSession(user)
                  .then((session) => debugPrint('Session created'))
                  .catchError(
                    (error) => debugPrint('Error creating session: $error'),
              );
            }
            await CubeChatConnection.instance.login(user);

            await CubeChatConnection.instance
                .login(user)
                .then((user) => debugPrint('User logged in'))
                .catchError((error) => debugPrint('Error logging in: $error'));
          } else {
            throw Exception("No valid user credentials found");
          }
        }

        _callClient = P2PClient.instance;

        _callClient?.init();
        _isInitialized = true;
        showLog('P2P client initialized successfully');
      } catch (e) {
        showLog('Error initializing P2P client: $e');
        _isInitialized = false;
        rethrow;
      }
    }
  }

  // Helper method to get active session
  Future<CubeSession?> getActiveSession() async {
    try {
      return await getSession();
    } catch (e) {
      showLog('Error getting active session: $e');
      return null;
    }
  }

  // Update your listenForIncomingCalls method to store active session and show notification
  void listenForIncomingCalls({
    required Function(P2PSession) onIncomingCall,
    required Function(P2PSession) onCallSessionClosed,
  }) async {
    debugPrint("Call incoming");
    if (!_isInitialized) {
      await initCallClient();
    }

    _callClient?.onReceiveNewSession = (session) async {
      debugPrint("session=======$session");
      // Store active session
      activeCallSession = session;

      // Get caller information to display in notification
      String callerName = "Unknown Caller";
      try {
        var user = await getUserById(session.callerId);
        if (user != null) {
          callerName =
              user.fullName ?? user.login ?? "User ${session.callerId}";
        }
      } catch (e) {
        debugPrint('Error getting caller info: $e');
      }

      // Show call notification
      await _showIncomingCallNotification(session, callerName);

      // Notify app
      onIncomingCall(session);
    };

    _callClient?.onSessionClosed = (session) {
      // Clear the reference to the active session
      if (activeCallSession?.sessionId == session.sessionId) {
        activeCallSession = null;
      }

      // Report call ended to system
      ConnectycubeFlutterCallKit.reportCallEnded(sessionId: session.sessionId);

      // Notify app
      onCallSessionClosed(session);
    };
  }

  // Show incoming call notification
  Future<void> _showIncomingCallNotification(
      P2PSession session,
      String callerName,
      ) async {
    showLog("Entered showIncomingCallNotification ---------");
    final callEvent = CallEvent(
        sessionId: session.sessionId,
        callType: session.callType,
        callerId: session.callerId,
        callerName: callerName,
        opponentsIds: session.opponentsIds.toSet(),
        callPhoto: 'https://i.imgur.com/KwrDil8b.jpg',
        userInfo: {'customParameter1': 'value1'});
    showLog(
        "Entered showIncomingCallNotification Call event--------- $callEvent");
    await ConnectycubeFlutterCallKit.showCallNotification(callEvent);
  }

  // Update the accept/reject methods to report to Call Kit
  void acceptCall(P2PSession session) {
    Map<String, String> userInfo = {'acceptedBy': 'customer'};
    session.acceptCall(userInfo);

    // Report to system that call was accepted
    ConnectycubeFlutterCallKit.reportCallAccepted(sessionId: session.sessionId);
  }

  void rejectCall(P2PSession session) {
    Map<String, String> userInfo = {'rejectedBy': 'customer'};
    session.reject(userInfo);

    // Report to system that call was ended
    ConnectycubeFlutterCallKit.reportCallEnded(sessionId: session.sessionId);
  }

  void endCall(P2PSession session) {
    session.hungUp();
    session.closeCurrentSession();
    ConnectycubeFlutterCallKit.reportCallEnded(sessionId: session.sessionId);
  }

  void toggleMute(P2PSession session, bool mute) {
    session.setMicrophoneMute(mute);

    // Report mute state to system
    ConnectycubeFlutterCallKit.reportCallMuted(
      sessionId: session.sessionId,
      muted: mute,
    );
  }

  Future<void> fetchUnreadDialogs({required BuildContext context}) async {
    try {
      Map<String, dynamic> additionalParams = {};

      var pagedResult = await getDialogs(additionalParams);
      if (pagedResult?.items != null && pagedResult!.items.isNotEmpty) {
        dialogsList = pagedResult.items;
        if (context.mounted) {
          // context
          //     .read<TotalUnreadInboxCubit>()
          //     .setDialogsTotalUnread(pagedResult.items);
        }
      }
    } catch (error) {
      debugPrint('Error fetching dialogs: $error');
    }
  }

  Future<void> listenUnreadForMessages({required BuildContext context}) async {
    CubeChatConnection.instance.chatMessagesManager?.chatMessagesStream
        .listen((newMessage) {
      String dialogId = newMessage.dialogId ?? '';
      if (messagesByDialog[dialogId] != null) {
        messagesByDialog[dialogId]!.add(newMessage);
      } else {
        messagesByDialog[dialogId] = [newMessage];
      }
      _updateDialogWithNewMessage(dialogId, newMessage, context: context);
    }).onError((error) {
      debugPrint('Error receiving message: $error');
    });
  }

  void _updateDialogWithNewMessage(
      String dialogId,
      CubeMessage newMessage, {
        required BuildContext context,
      }) {
    for (var dialog in dialogsList) {
      if (dialog.dialogId == dialogId) {
        dialog.lastMessage = newMessage.body;
        dialog.unreadMessageCount = (dialog.unreadMessageCount ?? 0) + 1;
        // context
        //     .read<TotalUnreadInboxCubit>()
        //     .setDialogsTotalUnread(dialogsList, dialogId: dialogId);
        break;
      }
    }
  }

  Future<void> inboxLogin({String? email}) async {
    CubeUser user = CubeUser()
      ..email = HydratedBloc.storage.read(HydrateConstant.customerEmail)
      ..password = '1234567890';
    showLog(
        "CALL 1 :: ${HydratedBloc.storage.read(HydrateConstant.customerEmail)}");
    await createSession(user).then((cubeSession) async {
      await HydratedBloc.storage.write(
        HydrateConstant.connectyCubeId,
        cubeSession.user?.id ?? 0,
      );
      await connectTOChat(
        id: cubeSession.user?.id.toString() ?? '',
        email: email,
      );
      showLog("connect To Chat :: ${cubeSession.user?.id}, $email");
      await initCallClient();
    }).catchError((error) {
      debugPrint('error is aa $error');
    });
  }

  Future<void> connectTOChat({String? id, String? email}) async {
    final userId = int.tryParse(
      id ??
          HydratedBloc.storage.read(HydrateConstant.connectyCubeId).toString(),
    );
    CubeUser user = CubeUser()
      ..id = userId
      ..email =
          email ?? HydratedBloc.storage.read(HydrateConstant.customerEmail)
      ..password = '1234567890';
    showLog("CALL 2 :: ${email.toString}");
    await CubeChatConnection.instance.login(user).then((loggedUser) async {
      // await getToken();
      debugPrint('connect to chat ........ ${loggedUser.toJson()}');
    }).catchError((error) {
      debugPrint('error is $error');
    });
  }

  // Call functionality
  Future<P2PSession?> initiateCall(
      int opponentId, {
        bool isVideoCall = false,
      }) async {
    debugPrint("Initiate call????%%$_isInitialized");
    try {
      // Make sure call client is initialized
      if (!_isInitialized) {
        debugPrint("Init????%%$_isInitialized");

        await initCallClient();
      }

      // Create call session
      final callType = CallType.AUDIO_CALL;
      final session = _callClient?.createCallSession(callType, {opponentId});
      debugPrint("Init????%%$session");

      if (session != null) {
        debugPrint("Session check????%%$session");

        // Start the call
        Map<String, String> userInfo = {'caller': 'customer'};
        debugPrint("Start Call????%%$session");

        session.startCall(userInfo);
        return session;
      }
      return null;
    } catch (e) {
      debugPrint('Error initiating call: $e');
      return null;
    }
  }

  // Set up call session listeners
  void setupCallSessionListeners(
      P2PSession session, {
        Function(MediaStream)? onLocalStreamReceived,
        Function(P2PSession, int, MediaStream)? onRemoteStreamReceived,
        Function(P2PSession, int)? onUserNoAnswer,
        Function(P2PSession, int, Map<String, String>?)? onCallRejectedByUser,
        Function(P2PSession, int, Map<String, String>?)? onCallAcceptedByUser,
        Function(P2PSession, int, Map<String, String>?)? onReceiveHungUpFromUser,
        Function(P2PSession)? onSessionClosed,
      }) {
    if (onLocalStreamReceived != null) {
      session.onLocalStreamReceived = onLocalStreamReceived;
    }

    if (onRemoteStreamReceived != null) {
      session.onRemoteStreamReceived = (session, userId, stream) {
        onRemoteStreamReceived(session as P2PSession, userId, stream);
      };
    }

    if (onUserNoAnswer != null) {
      session.onUserNoAnswer = onUserNoAnswer;
    }

    if (onCallRejectedByUser != null) {
      session.onCallRejectedByUser = (callSession, opponentId, [userInfo]) {
        debugPrint("Reject call from repo");
        onCallRejectedByUser(session, opponentId, userInfo);
      };
    }

    if (onCallAcceptedByUser != null) {
      session.onCallAcceptedByUser = (callSession, opponentId, [userInfo]) {
        debugPrint("Accept call from repo");

        onCallAcceptedByUser(session, opponentId, userInfo);
      };
    }

    if (onReceiveHungUpFromUser != null) {
      session.onReceiveHungUpFromUser = (callSession, opponentId, [userInfo]) {
        debugPrint("Hung up call from repo");
        onReceiveHungUpFromUser(session, opponentId, userInfo);
      };
    }

    if (onSessionClosed != null) {
      session.onSessionClosed = (session) {
        debugPrint("Session Closes call from repo");
        onSessionClosed(session as P2PSession);
      };
    }
  }
}

*/
