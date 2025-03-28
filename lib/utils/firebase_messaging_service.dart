import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:medconnect/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:medconnect/screens/shared/call_invitation_page.dart';

class FirebaseMessagingService {
  static Future<void> initializeFCM() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        // Save the token in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', fcmToken);
        print('FCM Token saved: $fcmToken');
      } else {
        print('Failed to generate FCM token');
      }

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleMessage(message);
      });

      // Handle messages when the app is opened from a terminated state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessage(message);
      });
    } catch (e) {
      print('Error initializing FCM: $e');
    }
  }

  static void _handleMessage(RemoteMessage message) {
    if (message.data['type'] == 'call_invitation') {
      final channelName = message.data['channelName'];
      final callerName = message.data['callerName'];

      // Navigate to the CallInvitationPage
      Navigator.push(
        MyApp.navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (context) => CallInvitationPage(
            channelName: channelName,
            callerName: callerName,
          ),
        ),
      );
    }
  }

  static Future<String?> getDeviceToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      print('Error fetching FCM token: $e');
      return null;
    }
  }
}
