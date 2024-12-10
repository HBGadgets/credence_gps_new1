// notification_provider.dart
import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  bool _hasNewNotification = false;
  String _notificationTitle = '';
  String _notificationDescription = '';

  bool get hasNewNotification => _hasNewNotification;
  String get notificationTitle => _notificationTitle;
  String get notificationDescription => _notificationDescription;

  void setNewNotification(String title, String description) {
    _hasNewNotification = true;
    _notificationTitle = title;
    _notificationDescription = description;
    notifyListeners();
  }

  void clearNotification() {
    _hasNewNotification = false;
    _notificationTitle = '';
    _notificationDescription = '';
    notifyListeners();
  }
}
