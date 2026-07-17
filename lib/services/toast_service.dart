import 'package:flutter/material.dart';

class ToastData {
  final Widget child;
  final Duration duration;

  const ToastData({required this.child, required this.duration});
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
