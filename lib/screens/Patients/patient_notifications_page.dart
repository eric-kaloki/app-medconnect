import 'package:flutter/material.dart';

class PatientNotificationsPage extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;

  const PatientNotificationsPage({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('No notifications to show.'))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  title: Text(notification['title']),
                  subtitle: Text(notification['body']),
                  trailing: notification['isRead']
                      ? null
                      : const Icon(Icons.circle, color: Colors.red, size: 10),
                );
              },
            ),
    );
  }
}
