import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:medconnect/screens/auth/choose_user_role.dart';
import 'package:medconnect/screens/shared/call_invitation_page.dart';
import 'package:medconnect/screens/shared/video_call_page.dart';
import 'package:medconnect/utils/config.dart';
import 'package:medconnect/utils/routes.dart';
import 'package:medconnect/utils/firebase_messaging_service.dart';
import 'firebase_options.dart'; // Import the generated Firebase options

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize FCM and save the token
  await FirebaseMessagingService.initializeFCM();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static final navigatorKey = GlobalKey<NavigatorState>();
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Debug: Received FCM message: ${message.data}');

      if (message.data['type'] == 'call-invitation') {
        final channelName = message.data['channelName'];
        final callerName = message.data['callerName'];

        print('Debug: Extracted channelName: $channelName (Type: ${channelName.runtimeType})');
        print('Debug: Extracted callerName: $callerName (Type: ${callerName.runtimeType})');

        if (channelName is! String || callerName is! String) {
          print('Error: Invalid data types in FCM message.');
          return;
        }

        navigatorKey.currentState?.pushNamed(
          '/call-invitation',
          arguments: {
            'channelName': channelName,
            'callerName': callerName,
          },
        );
      } else {
        print('Debug: Non-call invitation FCM message received: ${message.data}');
      }
    });

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MedConnect',
      home: const ChooseUserRole(),
      routes: {
        ...AppRoutes.routes,
        '/call-invitation': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          final channelName = args['channelName'] as String;
          final callerName = args['callerName'] as String;

          print('Debug: Decoded arguments for CallInvitationPage - channelName: $channelName, callerName: $callerName');

          return CallInvitationPage(
            channelName: channelName,
            callerName: callerName,
          );
        },
        '/video-call': (context) => VideoCallPage(
              channelName: ModalRoute.of(context)!.settings.arguments as String,
            ),
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        inputDecorationTheme: const InputDecorationTheme(
          focusColor: Config.primaryColor,
          border: Config.outlinedBorder,
          focusedBorder: Config.focusBorder,
          errorBorder: Config.errorBorder,
          enabledBorder: Config.outlinedBorder,
          floatingLabelStyle: TextStyle(color: Config.primaryColor),
          prefixIconColor: Colors.black38,
        ),
        scaffoldBackgroundColor: Colors.white,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Config.primaryColor,
          selectedItemColor: Colors.white,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          unselectedItemColor: Colors.grey.shade700,
          elevation: 10,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
