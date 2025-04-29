//set constant config here
import 'package:flutter/material.dart';

class Config {
  static String apiUrl = 'https://server-medconnect-kdeb.onrender.com';

  static const String signalingServerAddress = 'https://server-medconnect-kdeb.onrender.com';
  // static String appId = "e6763f01e6344d418daa06bf25ad459f";
  // static String channelName = "test";

  static const String turnServerUrl = 'turn:turn.googleapis.com';
  static const String turnServerUsername = 'user';
  static const String turnServerCredential = 'password';

  static const List<Map<String, String>> stunServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
    {'urls': 'stun:stun3.l.google.com:19302'},
  ];

  static MediaQueryData? mediaQueryData;
  static double? screenWidth;
  static double? screenHeight;

  //width and height initialization
  void init(BuildContext context) {
    mediaQueryData = MediaQuery.of(context);
    screenWidth = mediaQueryData!.size.width;
    screenHeight = mediaQueryData!.size.height;
  }

  static get widthSize {
    return screenWidth;
  }

  static get heightSize {
    return screenHeight;
  }

  //define spacing height
  static const spaceSmall = SizedBox(
    height: 25,
  );
  static final spaceMedium = SizedBox(
    height: screenHeight! * 0.05,
  );
  static final spaceBig = SizedBox(
    height: screenHeight! * 0.08,
  );

  //textform field border
  static const outlinedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );

  static const focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(
        color: Colors.greenAccent,
      ));
  static const errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(
        color: Colors.red,
      ));

  static const primaryColor = Color.fromARGB(255, 174, 255, 216);
  static const buttonColor = Color.fromARGB(255, 57, 230, 146);
}