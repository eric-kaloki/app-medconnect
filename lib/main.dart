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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use Firebase options
  );
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
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MedConnect',
      home: const ChooseUserRole(),
      routes: {
        ...AppRoutes.routes,
        '/call-invitation': (context) => CallInvitationPage(
              channelName: ModalRoute.of(context)!.settings.arguments as String,
              callerName: 'Caller Name', // Replace with actual caller name
            ),
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
