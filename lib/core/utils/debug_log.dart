import 'package:flutter/foundation.dart';

class DebugLog {
  const DebugLog._();

  static void message(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void error(Object error, {StackTrace? stackTrace, String? context}) {
    if (kDebugMode) {
      debugPrint('${context ?? 'Error'}: $error');
      if (stackTrace != null) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }
}
