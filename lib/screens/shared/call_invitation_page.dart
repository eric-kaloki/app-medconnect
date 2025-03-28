import 'package:flutter/material.dart';
import 'package:medconnect/screens/shared/video_call_page.dart';
import 'package:dio/dio.dart';
import 'package:medconnect/utils/config.dart';

class CallInvitationPage extends StatelessWidget {
  final String channelName;
  final String callerName;

  const CallInvitationPage({
    Key? key,
    required this.channelName,
    required this.callerName,
  }) : super(key: key);

  void _respondToCall(BuildContext context, String response) async {
    final dio = Dio();
    try {
      await dio.post('${Config.apiUrl}/call-response', data: {
        'channelName': channelName,
        'response': response,
      });
      if (response == 'accepted') {
        // Navigate to the video call page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallPage(channelName: channelName),
          ),
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error sending call response: $e');
    }
  }

  void _sendAcknowledgment(String status) async {
    final dio = Dio();
    try {
      await dio.post('${Config.apiUrl}/invitation-acknowledgment', data: {
        'channelName': channelName,
        'status': status, // e.g., "received", "ignored", "answered"
      });
      debugPrint('Acknowledgment sent: $status');
    } catch (e) {
      debugPrint('Error sending acknowledgment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Send acknowledgment when the page is opened
    _sendAcknowledgment('received');

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
                    _sendAcknowledgment('answered');
                    _respondToCall(context, 'accepted');
                  },
                  child: const Text('Answer'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _sendAcknowledgment('ignored');
                    _respondToCall(context, 'declined');
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
