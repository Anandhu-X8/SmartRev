import 'package:flutter/material.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic)
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    
    final int totalQuestions = args['totalQuestions'] ?? 5;
    final int correctAnswers = args['correctAnswers'] ?? 0;
    final int wrongAnswers = args['wrongAnswers'] ?? (totalQuestions - correctAnswers);
    final int scorePercentage = args['scorePercentage'] ?? (totalQuestions > 0 ? ((correctAnswers / totalQuestions) * 100).toInt() : 0);
    final String topicId = args['topicId'] ?? '';

    // Performance Label Logic
    String performanceLabel = '';
    Color performanceColor = Colors.grey;
    if (scorePercentage <= 40) {
      performanceLabel = 'Weak';
      performanceColor = const Color(0xFFEF4444); // Red
    } else if (scorePercentage <= 70) {
      performanceLabel = 'Moderate';
      performanceColor = const Color(0xFFF59E0B); // Orange
    } else {
      performanceLabel = 'Strong';
      performanceColor = const Color(0xFF10B981); // Green
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (context, child) {
                    final currentPercentage = (_scoreAnimation.value * scorePercentage).toInt();
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: CircularProgressIndicator(
                            value: _scoreAnimation.value * (correctAnswers / totalQuestions),
                            strokeWidth: 16,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            color: performanceColor,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$currentPercentage%',
                              style: theme.textTheme.displayLarge?.copyWith(
                                color: theme.textTheme.bodyLarge?.color,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 8),
                Text(
                  performanceLabel.toUpperCase(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: performanceColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn('Total\nQuestions', totalQuestions.toString(), theme.primaryColor, theme),
                            Container(width: 1, height: 40, color: Colors.grey.shade200),
                            _buildStatColumn('Correct\nAnswers', correctAnswers.toString(), const Color(0xFF10B981), theme),
                            Container(width: 1, height: 40, color: Colors.grey.shade200),
                            _buildStatColumn('Wrong\nAnswers', wrongAnswers.toString(), const Color(0xFFEF4444), theme),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to review answers screen (currently pops back or could push a new route)
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: theme.primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Review Answers', style: TextStyle(fontSize: 18, color: theme.primaryColor)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Back to Dashboard', style: TextStyle(fontSize: 18)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
