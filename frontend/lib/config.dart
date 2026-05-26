import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Backend API base URL.
/// Use 10.0.2.2 for Android emulator, localhost for iOS simulator/web,
/// or your machine's IP for physical devices.
String get apiBase {
  if (kIsWeb) return 'https://smartrev.onrender.com';
  if (Platform.isAndroid) return 'https://smartrev.onrender.com';
  if (Platform.isIOS) return 'https://smartrev.onrender.com';
  return 'https://smartrev.onrender.com';
}
