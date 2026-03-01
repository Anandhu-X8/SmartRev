import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_topic_screen.dart';
import 'screens/revision_screen.dart';
import 'screens/results_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/upload_notes_screen.dart';
import 'screens/flashcard_revision_screen.dart';
import 'providers/topics_provider.dart';

/// Auth provider that holds login state and username.
class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String _username = 'User';

  bool get isAuthenticated => _isAuthenticated;
  String get username => _username;

  /// Called on login to store the username in state.
  void login(String username) {
    _username = username.isNotEmpty ? username : 'User';
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _username = 'User';
    _isAuthenticated = false;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (wrapped in try-catch in case options not provided yet)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TopicsProvider()),
      ],
      child: const SmartRevisionApp(),
    ),
  );
}

class SmartRevisionApp extends StatelessWidget {
  const SmartRevisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Revision',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/add-topic': (context) => const AddTopicScreen(),
        '/revision': (context) => const RevisionScreen(),
        '/results': (context) => const ResultsScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/upload-notes': (context) => const UploadNotesScreen(),
        '/flashcard-revision': (context) => const FlashcardRevisionScreen(),
      },
    );
  }
}
