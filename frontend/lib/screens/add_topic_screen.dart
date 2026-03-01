import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/topics_provider.dart';

/// Screen for adding a new topic with flashcards.
/// Users enter topic metadata once, then add unlimited Q&A flashcards.
class AddTopicScreen extends StatefulWidget {
  const AddTopicScreen({super.key});

  @override
  State<AddTopicScreen> createState() => _AddTopicScreenState();
}

class _AddTopicScreenState extends State<AddTopicScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _subject = '';
  String _difficulty = 'Medium';
  double _confidence = 3;

  // Controllers for flashcard Q&A (cleared after each "Add Flashcard")
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  // Accumulated flashcards for this topic
  final List<Flashcard> _flashcards = [];

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  /// Adds the current Q&A as a flashcard and clears only the Q&A fields.
  void _addFlashcard() {
    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();

    if (question.isEmpty || answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in both Question and Answer.'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _flashcards.add(Flashcard(question: question, answer: answer));
      // Clear only Q&A — topic metadata stays
      _questionController.clear();
      _answerController.clear();
    });
  }

  /// Saves the topic with all accumulated flashcards.
  void _saveTopic() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Check at least one flashcard was added
      if (_flashcards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Add at least one flashcard before saving.'),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      Provider.of<TopicsProvider>(context, listen: false)
          .addTopic(_name, _subject, _difficulty, _confidence, flashcards: _flashcards);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Topic Added with ${_flashcards.length} flashcard(s)!'),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Topic'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Topic Details',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your topic info, then add flashcards below.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              
              // --- Topic Name ---
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Topic Name',
                  hintText: 'e.g. Flutter State Management',
                  prefixIcon: Icon(Icons.menu_book, color: theme.primaryColor),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                onSaved: (val) => _name = val!,
              ),
              const SizedBox(height: 20),
              
              // --- Subject Category ---
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Subject Category',
                  hintText: 'e.g. Programming',
                  prefixIcon: Icon(Icons.category, color: theme.primaryColor),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter a subject' : null,
                onSaved: (val) => _subject = val!,
              ),
              const SizedBox(height: 32),
              
              // --- Difficulty Level ---
              Text(
                'Difficulty Level',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),
              Row(
                children: ['Easy', 'Medium', 'Hard'].map((diff) {
                  final isSelected = _difficulty == diff;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: ChoiceChip(
                      label: Text(diff),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _difficulty = diff);
                        }
                      },
                      selectedColor: theme.colorScheme.secondary,
                      labelStyle: TextStyle(
                        color: isSelected ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? theme.primaryColor : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              
              // --- Confidence Slider ---
              Text(
                'Initial Confidence Level',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                   const Text('Low', style: TextStyle(color: Colors.grey)),
                   Expanded(
                     child: Slider(
                      value: _confidence,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: theme.primaryColor,
                      onChanged: (val) {
                        setState(() { _confidence = val; });
                      },
                    ),
                   ),
                   const Text('High', style: TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 32),

              // --- Flashcard Section ---
              Divider(color: theme.primaryColor.withOpacity(0.3)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Flashcards',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                  ),
                  // Live counter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Added: ${_flashcards.length}',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Question Field ---
              TextFormField(
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: 'Question',
                  hintText: 'e.g. What is a StatefulWidget?',
                  prefixIcon: Icon(Icons.help_outline, color: theme.primaryColor),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // --- Answer Field ---
              TextFormField(
                controller: _answerController,
                decoration: InputDecoration(
                  labelText: 'Answer',
                  hintText: 'e.g. A widget that has mutable state.',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Icon(Icons.lightbulb_outline, color: theme.primaryColor),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // --- Add Flashcard Button ---
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addFlashcard,
                  icon: Icon(Icons.add_circle_outline, color: theme.primaryColor),
                  label: Text(
                    'Add Flashcard',
                    style: TextStyle(fontSize: 16, color: theme.primaryColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: theme.primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              // --- Added Flashcards Preview ---
              if (_flashcards.isNotEmpty) ...[
                const SizedBox(height: 20),
                ...List.generate(_flashcards.length, (i) {
                  final fc = _flashcards[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.primaryColor.withOpacity(0.15),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(color: theme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fc.question,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Remove flashcard button
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                          onPressed: () {
                            setState(() => _flashcards.removeAt(i));
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 32),
              
              // --- Save Topic Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTopic,
                  child: const Text('Save Topic', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
