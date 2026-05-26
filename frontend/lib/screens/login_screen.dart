import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../main.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  bool _isSignUp = false;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      UserCredential credential;
      if (_isSignUp) {
        final displayName = _displayNameController.text.trim();
        if (displayName.isEmpty) {
          _showError('Please enter your name');
          setState(() => _isLoading = false);
          return;
        }
        credential = await firebaseService.signUp(
          email: email,
          password: password,
          displayName: displayName,
        );
      } else {
        credential = await firebaseService.signIn(
          email: email,
          password: password,
        );
      }

      final user = credential.user;
      if (user != null) {
        final token = await user.getIdToken();
        if (!mounted) return;
        authProvider.login(
          user.displayName ?? email.split('@').first,
          uid: user.uid,
          token: token,
        );
        // Initialize push notifications
        final notifService = Provider.of<NotificationService>(context, listen: false);
        await notifService.init(user.uid);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Authentication failed');
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.secondary.withValues(alpha: 0.5),
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Headlines
                  Text(
                    'Welcome to SmartRev',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your AI-powered revision assistant',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login Card
                  Card(
                    elevation: 10,
                    shadowColor: theme.primaryColor.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isSignUp)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: TextField(
                                controller: _displayNameController,
                                decoration: InputDecoration(
                                  labelText: 'Display Name',
                                  prefixIcon: Icon(Icons.badge_outlined,
                                      color: theme.primaryColor),
                                ),
                              ),
                            ),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: theme.primaryColor),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: theme.primaryColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!_isSignUp)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  theme.primaryColor,
                                  const Color(0xFF059669),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(_isSignUp ? 'Sign Up' : 'Log In'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Toggle sign up / log in
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp
                            ? 'Already have an account?'
                            : "Don't have an account?",
                        style: theme.textTheme.bodyLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _isSignUp = !_isSignUp);
                        },
                        child: Text(
                          _isSignUp ? 'Log In' : 'Sign Up',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
