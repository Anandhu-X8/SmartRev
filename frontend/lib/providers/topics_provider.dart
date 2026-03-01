import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class Quiz {
  final String id;
  final List<QuizQuestion> questions;

  Quiz({
    required this.id,
    required this.questions,
  });
}

/// A single flashcard with a question and answer pair.
class Flashcard {
  final String question;
  final String answer;

  Flashcard({required this.question, required this.answer});
}

/// Represents a study topic with optional flashcards and/or AI quiz.
class Topic {
  final String id;
  final String name;
  final String subject;
  final String difficulty;
  final double initialConfidence;
  int memoryStrength;
  String nextRevisionDate;
  String reviseStatus; // "today" or "later"
  List<Flashcard> flashcards;
  Quiz? quiz;
  bool isAiGenerated;

  Topic({
    required this.id,
    required this.name,
    required this.subject,
    this.difficulty = 'Medium',
    this.initialConfidence = 3.0,
    required this.memoryStrength,
    required this.nextRevisionDate,
    this.reviseStatus = 'today',
    this.flashcards = const [],
    this.quiz,
    this.isAiGenerated = false,
  });
}

class TopicsProvider extends ChangeNotifier {
  final List<Topic> _topics = [
    Topic(
      id: '1',
      name: 'Flutter State Management',
      subject: 'Programming',
      difficulty: 'Medium',
      initialConfidence: 3.0,
      memoryStrength: 45,
      nextRevisionDate: 'Today',
      reviseStatus: 'today',
      flashcards: [
        Flashcard(question: 'What is a ChangeNotifier?', answer: 'A class that provides change notification to its listeners.'),
        Flashcard(question: 'What does Provider do?', answer: 'Provider is a wrapper around InheritedWidget to make state accessible.'),
      ],
    ),
    Topic(
      id: '2',
      name: 'Python Decorators',
      subject: 'Programming',
      difficulty: 'Hard',
      initialConfidence: 2.0,
      memoryStrength: 60,
      nextRevisionDate: 'Today',
      reviseStatus: 'today',
      flashcards: [
        Flashcard(question: 'What is a decorator in Python?', answer: 'A function that takes another function and extends its behavior.'),
        Flashcard(question: 'What does @staticmethod do?', answer: 'Defines a method that does not receive an implicit first argument (self/cls).'),
      ],
    ),
    Topic(
      id: '3',
      name: 'Spaced Repetition Math',
      subject: 'Algorithms',
      difficulty: 'Easy',
      initialConfidence: 4.0,
      memoryStrength: 80,
      nextRevisionDate: 'Tomorrow',
      reviseStatus: 'later',
      flashcards: [
        Flashcard(question: 'What is spaced repetition?', answer: 'A learning technique that incorporates increasing intervals of time between review of previously learned material.'),
      ],
    ),
  ];

  List<Topic> get topics => _topics;

  /// Returns all topics that should be revised today.
  /// Dynamically filters from the main list — no duplicate storage.
  List<Topic> get todaysRevisionQueue {
    return _topics.where((t) => t.reviseStatus == 'today').toList();
  }

  /// Add a new topic with flashcards.
  void addTopic(
    String name,
    String subject,
    String difficulty,
    double confidence, {
    List<Flashcard> flashcards = const [],
  }) {
    // Determine initial strength based on confidence (1-5)
    int strength = (confidence * 20).toInt();

    final newTopic = Topic(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      subject: subject,
      difficulty: difficulty,
      initialConfidence: confidence,
      memoryStrength: strength,
      nextRevisionDate: 'Today',
      reviseStatus: 'today',
      flashcards: List<Flashcard>.from(flashcards),
    );

    _topics.add(newTopic);
    notifyListeners();
  }

  /// Update memory strength after flashcard revision with confidence slider.
  void updateMemoryStrength(String topicId, int newStrength) {
    final topicIndex = _topics.indexWhere((t) => t.id == topicId);
    if (topicIndex >= 0) {
      final topic = _topics[topicIndex];
      topic.memoryStrength = newStrength.clamp(0, 100);

      // If strong memory, schedule for later; otherwise keep today
      if (newStrength >= 70) {
        topic.reviseStatus = 'later';
        topic.nextRevisionDate = 'Tomorrow';
      } else {
        topic.reviseStatus = 'today';
        topic.nextRevisionDate = 'Today';
      }

      notifyListeners();
    }
  }

  /// Update topic results after quiz-based revision (existing flow).
  void updateTopicResults(String topicId, int correctAnswers, int memoryStrengthChange) {
    final topicIndex = _topics.indexWhere((t) => t.id == topicId);
    if (topicIndex >= 0) {
      final topic = _topics[topicIndex];
      int newStrength = topic.memoryStrength + memoryStrengthChange;
      newStrength = newStrength.clamp(0, 100);

      topic.memoryStrength = newStrength;

      if (correctAnswers >= 4) {
        topic.nextRevisionDate = 'Tomorrow';
        topic.reviseStatus = 'later';
      } else {
        topic.nextRevisionDate = 'Today';
        topic.reviseStatus = 'today';
      }

      notifyListeners();
    }
  }

  Future<void> uploadNotesAndGenerateQuiz(PlatformFile file, String topicName) async {
    final uri = Uri.parse('http://localhost:8000/api/notes/upload');
    var request = http.MultipartRequest('POST', uri);

    if (topicName.isNotEmpty) {
      request.fields['topic_name'] = topicName;
    }

    if (file.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ),
      );
    } else if (file.path != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ),
      );
    } else {
      throw Exception('Cannot read file data');
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final responseData = json.decode(response.body);
      final List<dynamic> rawQuestions = responseData['questions'] ?? [];

      final mappedQuestions = rawQuestions.map((q) => QuizQuestion(
        question: q['question'] ?? '',
        options: List<String>.from(q['options'] ?? []),
        correctAnswerIndex: q['correct_answer_index'] ?? 0,
      )).toList();

      final realQuiz = Quiz(
        id: responseData['quiz_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        questions: mappedQuestions,
      );

      final tName = topicName.isNotEmpty ? topicName : file.name.split('.').first;

      final newTopic = Topic(
        id: responseData['topic_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: tName,
        subject: 'Uploaded Notes',
        memoryStrength: 50,
        nextRevisionDate: 'Today',
        reviseStatus: 'today',
        quiz: realQuiz,
        isAiGenerated: true,
      );

      _topics.insert(0, newTopic);
      notifyListeners();
    } else {
      var err = 'Failed API Request';
      try {
        err = json.decode(response.body)['detail'] ?? err;
      } catch(_) {}
      throw Exception(err);
    }
  }
}
