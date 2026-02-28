import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/topics_provider.dart';

class RevisionScreen extends StatefulWidget {
  const RevisionScreen({super.key});

  @override
  State<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends State<RevisionScreen> with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  bool _showAnswer = false;
  int? _selectedOption;
  int _correctAnswers = 0;
  List<int> _userAnswers = [];
  
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  // Dummy Activity Data fallback if no quiz provided
  late List<dynamic> _questions = [];
  String _topicId = "dummy_id";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('quiz')) {
      final quiz = args['quiz']; // assume it's our new Quiz object
      _topicId = args['topicId'] ?? "dummy_id";
      _questions = quiz.questions.map((q) => {
        'question': q.question,
        'options': q.options,
        'correct_answer_index': q.correctAnswerIndex,
      }).toList();
    } else {
      // Default fallback
      _questions = [
        {
          'question': 'What is the widget used to create a material design app in Flutter?',
          'options': ['MaterialApp', 'Scaffold', 'Container', 'BuildContext'],
          'correct_answer_index': 0,
        },
        {
          'question': 'Which provider type listens to changes and rebuilds?',
          'options': ['Provider', 'ChangeNotifierProvider', 'FutureProvider', 'StreamProvider'],
          'correct_answer_index': 1,
        }
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnimation = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic)
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _submitAnswer() {
    setState(() {
      _showAnswer = true;
      _userAnswers.add(_selectedOption!);
      
      final currentQ = _questions[_currentQuestionIndex];
      if (_selectedOption == currentQ['correct_answer_index']) {
        _correctAnswers++;
      }
    });
    
    // Auto proceed or show Next button
    Future.delayed(const Duration(seconds: 2), () {
      if (_currentQuestionIndex < _questions.length - 1) {
        _animationController.reset();
        setState(() {
          _currentQuestionIndex++;
          _showAnswer = false;
          _selectedOption = null;
        });
        _animationController.forward();
      } else {
        // Calculate dynamic results
        final totalQuestions = _questions.length;
        final wrongAnswers = totalQuestions - _correctAnswers;
        final scorePercentage = totalQuestions > 0 ? ((_correctAnswers / totalQuestions) * 100).toInt() : 0;
        
        // Update local memory strength Provider Logic
        int strengthChange = 0;
        if (scorePercentage >= 80) {
           strengthChange = 15;
        } else if (scorePercentage >= 50) {
           strengthChange = 5;
        } else {
           strengthChange = -10;
        }
        
        if (_topicId != "dummy_id") {
          Provider.of<TopicsProvider>(context, listen: false).updateTopicResults(_topicId, _correctAnswers, strengthChange);
        }
        
        // Pass dynamic data instead of hardcoded 85% accuracy
        Navigator.pushReplacementNamed(context, '/results', arguments: {
          'topicId': _topicId,
          'totalQuestions': totalQuestions,
          'correctAnswers': _correctAnswers,
          'wrongAnswers': wrongAnswers,
          'scorePercentage': scorePercentage,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return const Center(child: CircularProgressIndicator());
    
    final theme = Theme.of(context);
    final questions = _questions;
    final questionMap = questions[_currentQuestionIndex];
    final questionText = questionMap['question'] as String;
    final options = questionMap['options'] as List<dynamic>;
    final correctIndex = questionMap['correct_answer_index'] as int;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Revision'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + (_showAnswer ? 1 : 0)) / questions.length,
            backgroundColor: theme.primaryColor.withOpacity(0.2),
            color: theme.primaryColor,
            minHeight: 6,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1} of ${questions.length}',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 8,
                      shadowColor: theme.primaryColor.withOpacity(0.15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          questionText,
                          style: theme.textTheme.titleLarge?.copyWith(fontSize: 22, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    ...List.generate(options.length, (index) {
                      final isSelected = _selectedOption == index;
                      final isCorrect = index == correctIndex;
                      
                      Color bgColor = theme.scaffoldBackgroundColor;
                      Color borderColor = Colors.grey.shade300;
                      Color textColor = theme.textTheme.bodyLarge!.color!;
                      
                      if (_showAnswer) {
                        if (isCorrect) {
                          bgColor = theme.colorScheme.primary.withOpacity(0.1);
                          borderColor = theme.colorScheme.primary;
                          textColor = theme.colorScheme.primary;
                        } else if (isSelected && !isCorrect) {
                          bgColor = theme.colorScheme.error.withOpacity(0.1);
                          borderColor = theme.colorScheme.error;
                          textColor = theme.colorScheme.error;
                        }
                      } else if (isSelected) {
                        bgColor = theme.primaryColor.withOpacity(0.05);
                        borderColor = theme.primaryColor;
                        textColor = theme.primaryColor;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border.all(color: borderColor, width: isSelected || (_showAnswer && isCorrect) ? 2 : 1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: _showAnswer ? null : () {
                              setState(() {
                                _selectedOption = index;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      options[index],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected || (_showAnswer && isCorrect) ? FontWeight.bold : FontWeight.normal,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  if (_showAnswer && isCorrect)
                                    Icon(Icons.check_circle, color: theme.primaryColor)
                                  else if (_showAnswer && isSelected && !isCorrect)
                                    Icon(Icons.cancel, color: theme.colorScheme.error)
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            SafeArea(
              child: ElevatedButton(
                onPressed: (_selectedOption == null || _showAnswer) ? null : _submitAnswer,
                child: const Text('Check Answer', style: TextStyle(fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
