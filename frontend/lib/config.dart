import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Backend API base URL.
/// Use 10.0.2.2 for Android emulator, localhost for iOS simulator/web,
/// or your machine's IP for physical devices.
String get apiBase {
  if (kIsWeb) return 'http://localhost:8000';
  if (Platform.isAndroid) return 'http://10.0.2.2:8000';
  if (Platform.isIOS) return 'http://localhost:8000';
  return 'http://localhost:8000';
}
