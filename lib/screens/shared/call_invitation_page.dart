import 'package:flutter/material.dart';
import 'package:medconnect/screens/shared/video_call_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class CallInvitationPage extends StatelessWidget {
  final String channelName;
  final String callerName;

  const CallInvitationPage({
    super.key,
    required this.channelName,
    required this.callerName,
  });

  static void handleIncomingCall(RemoteMessage message, BuildContext context) {
    if (message.data['type'] == 'call-invitation') {
      final channelName = message.data['channelName'];
      final callerName = message.data['callerName'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallInvitationPage(
            channelName: channelName,
            callerName: callerName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Debug: CallInvitationPage arguments - channelName: $channelName, callerName: $callerName');

    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Call')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Call from $callerName', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    print('Debug: Call accepted. Navigating to VideoCallPage with roomId: $channelName');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoCallPage(channelName: channelName),
                      ),
                    );
                  },
                  child: const Text('Answer'),
                ),
                ElevatedButton(
                  onPressed: () {
                    print('Debug: Call ignored. Returning to previous screen.');
                    Navigator.pop(context);
                  },
                  child: const Text('Ignore'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
