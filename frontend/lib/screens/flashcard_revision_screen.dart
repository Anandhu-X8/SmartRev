import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/topics_provider.dart';

/// Flashcard revision flow: shows flashcards one at a time with
/// Question → Reveal Answer → Next. After the last flashcard,
/// presents a confidence slider to update memory strength.
class FlashcardRevisionScreen extends StatefulWidget {
  const FlashcardRevisionScreen({super.key});

  @override
  State<FlashcardRevisionScreen> createState() => _FlashcardRevisionScreenState();
}

class _FlashcardRevisionScreenState extends State<FlashcardRevisionScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _answerRevealed = false;
  bool _showConfidenceSlider = false;
  double _confidenceValue = 3.0;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  String _topicId = '';
  List<Flashcard> _flashcards = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _topicId = args['topicId'] ?? '';
        // Fetch flashcards from provider by topic ID
        final provider = Provider.of<TopicsProvider>(context, listen: false);
        final topic = provider.topics.firstWhere(
          (t) => t.id == _topicId,
          orElse: () => Topic(id: '', name: '', subject: '', memoryStrength: 0, nextRevisionDate: ''),
        );
        _flashcards = topic.flashcards;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Move to the next flashcard or show the confidence slider.
  void _nextFlashcard() {
    if (_currentIndex < _flashcards.length - 1) {
      _animationController.reset();
      setState(() {
        _currentIndex++;
        _answerRevealed = false;
      });
      _animationController.forward();
    } else {
      // All flashcards done — show confidence slider
      setState(() {
        _showConfidenceSlider = true;
      });
    }
  }

  /// Submit confidence and update memory strength via provider.
  void _submitConfidence() {
    // Convert confidence (1-5) to memory strength (0-100)
    final newStrength = (_confidenceValue * 20).toInt();
    Provider.of<TopicsProvider>(context, listen: false)
        .updateMemoryStrength(_topicId, newStrength);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Memory strength updated!'),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Empty state
    if (_flashcards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcard Revision')),
        body: const Center(child: Text('No flashcards available for this topic.')),
      );
    }

    // Confidence slider after all flashcards
    if (_showConfidenceSlider) {
      return _buildConfidenceScreen(theme);
    }

    final flashcard = _flashcards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Revision'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: LinearProgressIndicator(
            value: (_currentIndex + (_answerRevealed ? 1 : 0)) / _flashcards.length,
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
            // Progress indicator
            Text(
              'Flashcard ${_currentIndex + 1} of ${_flashcards.length}',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Question card
                    Card(
                      elevation: 8,
                      shadowColor: theme.primaryColor.withOpacity(0.15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.help_outline, color: theme.primaryColor, size: 32),
                            const SizedBox(height: 16),
                            Text(
                              flashcard.question,
                              style: theme.textTheme.titleLarge?.copyWith(fontSize: 22, height: 1.4),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Answer card (shown when revealed)
                    if (_answerRevealed)
                      AnimatedOpacity(
                        opacity: _answerRevealed ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Card(
                          elevation: 4,
                          shadowColor: const Color(0xFF10B981).withOpacity(0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          color: const Color(0xFF10B981).withOpacity(0.05),
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                const Icon(Icons.lightbulb, color: Color(0xFF10B981), size: 28),
                                const SizedBox(height: 12),
                                Text(
                                  flashcard.answer,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 18,
                                    height: 1.5,
                                    color: const Color(0xFF065F46),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Action buttons
            SafeArea(
              child: _answerRevealed
                  ? ElevatedButton(
                      onPressed: _nextFlashcard,
                      child: Text(
                        _currentIndex < _flashcards.length - 1 ? 'Next' : 'Finish',
                        style: const TextStyle(fontSize: 18),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        setState(() => _answerRevealed = true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                      ),
                      child: const Text('Reveal Answer', style: TextStyle(fontSize: 18)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Screen shown after all flashcards are completed.
  /// Displays a confidence slider to update memory strength.
  Widget _buildConfidenceScreen(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Your Confidence')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Celebration icon
              Icon(
                Icons.emoji_events,
                size: 80,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Revision Complete!',
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You reviewed ${_flashcards.length} flashcard(s).\nHow confident do you feel?',
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Confidence label
              Text(
                'Confidence Level',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Low', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Expanded(
                    child: Slider(
                      value: _confidenceValue,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: theme.primaryColor,
                      label: _confidenceValue.toInt().toString(),
                      onChanged: (val) {
                        setState(() => _confidenceValue = val);
                      },
                    ),
                  ),
                  const Text('High', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              // Percentage preview
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Memory Strength: ${(_confidenceValue * 20).toInt()}%',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: _submitConfidence,
                child: const Text('Submit & Update', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
