import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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
import 'screens/profile_screen.dart';
import 'providers/topics_provider.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';

/// Auth provider that holds login state and username.
class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String _username = 'User';
  String? _userId;
  String? _idToken;

  bool get isAuthenticated => _isAuthenticated;
  String get username => _username;
  String? get userId => _userId;
  String? get idToken => _idToken;

  /// Called on login to store the username in state.
  void login(String username, {String? uid, String? token}) {
    _username = username.isNotEmpty ? username : 'User';
    _userId = uid;
    _idToken = token;
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _username = 'User';
    _userId = null;
    _idToken = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  final firebaseService = FirebaseService();
  final notificationService = NotificationService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => TopicsProvider(),
        ),
        Provider<FirebaseService>.value(value: firebaseService),
        Provider<NotificationService>.value(value: notificationService),
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
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
