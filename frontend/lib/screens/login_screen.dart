import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // Store username in AuthProvider state
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.login(_usernameController.text.trim());
    Navigator.pushReplacementNamed(context, '/home');
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
              theme.colorScheme.secondary.withOpacity(0.5),
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.4],
          )
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
                      color: theme.primaryColor.withOpacity(0.1),
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
                    shadowColor: theme.primaryColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline, color: theme.primaryColor),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline, color: theme.primaryColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
                                  Color(0xFF059669),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ),
                              child: const Text('Log In'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Sign up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: theme.textTheme.bodyLarge,
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Sign Up',
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
