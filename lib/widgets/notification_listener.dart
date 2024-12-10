// notification_listener_widget.dart
import 'package:credence/provider/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationListenerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        if (notificationProvider.hasNewNotification) {
          return Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  notificationProvider.notificationTitle,
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  notificationProvider.notificationDescription,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }
}
