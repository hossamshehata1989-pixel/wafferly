import 'package:flutter/material.dart';
import '../../theme/responsive_metrics.dart';
import '../../services/toast_service.dart';

class WafferlyToast {
  static void showError(BuildContext context, {required String message}) {
    ToastService.show(
      ToastData(
        message: message,
        type: ToastType.error,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  static void showSuccess(BuildContext context, {required String message}) {
    ToastService.show(
      ToastData(
        message: message,
        type: ToastType.success,
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  static void showWarning(BuildContext context, {required String message}) {
    ToastService.show(
      ToastData(
        message: message,
        type: ToastType.warning,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }
}
