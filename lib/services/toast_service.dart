import 'package:flutter/material.dart';

enum ToastType { success, error, warning }

class ToastData {
  final String message;
  final ToastType type;
  final Duration duration;

  ToastData({
    required this.message,
    required this.type,
    required this.duration,
  });
}

class ToastService {
  static final ValueNotifier<ToastData?> toast = ValueNotifier<ToastData?>(
    null,
  );

  static void show(ToastData data) {
    toast.value = data;
  }

  static void hide() {
    toast.value = null;
  }
}
