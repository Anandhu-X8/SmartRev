import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Backend API base URL - adjust for your environment
// Use 10.0.2.2 for Android emulator, localhost for iOS simulator/web, or your machine's IP for physical devices
String get _apiBase {
  // Check if running on web
  if (kIsWeb) {
    return 'http://localhost:8000';
  }
  
  // For mobile platforms, use dart:io Platform
  if (Platform.isAndroid) {
    // Android emulator uses 10.0.2.2 to access host machine's localhost
    return 'http://10.0.2.2:8000';
  } else if (Platform.isIOS) {
    // iOS simulator can use localhost
    return 'http://localhost:8000';
  }
  
  // Default to localhost for desktop
  return 'http://localhost:8000';
}

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

  /// Create Topic from backend JSON
  factory Topic.fromJson(Map<String, dynamic> json) {
    // Parse next_revision_date from backend
    String nextRev = 'Today';
    if (json['next_revision_date'] != null) {
      try {
        final dt = DateTime.parse(json['next_revision_date']);
        final now = DateTime.now();
        final diff = dt.difference(now).inDays;
        if (diff <= 0) {
          nextRev = 'Today';
        } else if (diff == 1) {
          nextRev = 'Tomorrow';
        } else {
          nextRev = 'In $diff days';
        }
      } catch (_) {}
    }

    // Parse flashcards from backend
    List<Flashcard> flashcards = [];
    if (json['flashcards'] != null) {
      final List<dynamic> rawFlashcards = json['flashcards'];
      flashcards = rawFlashcards.map((fc) => Flashcard(
        question: fc['question'] ?? '',
        answer: fc['answer'] ?? '',
      )).toList();
    }

    return Topic(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      subject: json['subject_category'] ?? json['subject'] ?? '',
      difficulty: json['difficulty_level'] ?? 'Medium',
      initialConfidence: (json['confidence_level'] ?? 3).toDouble(),
      memoryStrength: ((json['memory_strength'] ?? 50.0) as num).toInt(),
      nextRevisionDate: nextRev,
      reviseStatus: nextRev == 'Today' ? 'today' : 'later',
      isAiGenerated: json['is_ai_generated'] ?? false,
      flashcards: flashcards,
    );
  }
}

class TopicsProvider extends ChangeNotifier {
  List<Topic> _topics = [];
  bool _isLoading = false;
  static const String _topicsKey = 'cached_topics';

  List<Topic> get topics => _topics;
  bool get isLoading => _isLoading;

  /// Returns all topics that should be revised today.
  List<Topic> get todaysRevisionQueue {
    return _topics.where((t) => t.reviseStatus == 'today').toList();
  }

  /// Load topics from local storage
  Future<void> loadTopicsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final topicsJson = prefs.getString(_topicsKey);
      if (topicsJson != null) {
        final List<dynamic> data = json.decode(topicsJson);
        _topics = data.map((json) => Topic.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load topics from local storage: $e');
    }
  }

  /// Save topics to local storage
  Future<void> _saveTopicsToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final topicsJson = json.encode(_topics.map((topic) => {
        'id': topic.id,
        'name': topic.name,
        'subject_category': topic.subject,
        'difficulty_level': topic.difficulty,
        'confidence_level': topic.initialConfidence.toInt(),
        'memory_strength': topic.memoryStrength,
        'next_revision_date': topic.nextRevisionDate,
        'is_ai_generated': topic.isAiGenerated,
        'flashcards': topic.flashcards.map((fc) => {
          'question': fc.question,
          'answer': fc.answer,
        }).toList(),
      }).toList());
      await prefs.setString(_topicsKey, topicsJson);
    } catch (e) {
      debugPrint('Failed to save topics to local storage: $e');
    }
  }

  /// Fetch all topics from backend
  Future<void> fetchTopics() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$_apiBase/api/topics/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _topics = data.map((json) => Topic.fromJson(json)).toList();
        // Save to local storage for offline access
        await _saveTopicsToLocal();
      }
    } catch (e) {
      debugPrint('Failed to fetch topics: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch revision queue from backend
  Future<void> fetchRevisionQueue() async {
    try {
      final response = await http.get(Uri.parse('$_apiBase/api/revision/queue'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final queueTopics = data.map((json) => Topic.fromJson(json)).toList();
        
        // Update reviseStatus for topics in queue
        for (var queueTopic in queueTopics) {
          final idx = _topics.indexWhere((t) => t.id == queueTopic.id);
          if (idx >= 0) {
            _topics[idx].reviseStatus = 'today';
            _topics[idx].nextRevisionDate = 'Today';
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to fetch revision queue: $e');
    }
  }

  /// Add a new topic via backend API
  Future<void> addTopic(
    String name,
    String subject,
    String difficulty,
    double confidence, {
    List<Flashcard> flashcards = const [],
  }) async {
    try {
      // Convert flashcards to backend format
      final flashcardsJson = flashcards.map((f) => {
        'question': f.question,
        'answer': f.answer,
      }).toList();

      final response = await http.post(
        Uri.parse('$_apiBase/api/topics/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'subject_category': subject,
          'difficulty_level': difficulty,
          'confidence_level': confidence.toInt(),
          'notes': flashcards.isNotEmpty
              ? flashcards.map((f) => 'Q: ${f.question}\nA: ${f.answer}').join('\n\n')
              : null,
          'flashcards': flashcardsJson,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newTopic = Topic.fromJson(data);
        _topics.insert(0, newTopic);
        // Save to local storage
        await _saveTopicsToLocal();
        notifyListeners();
      } else {
        throw Exception('Failed to create topic: ${response.body}');
      }
    } catch (e) {
      debugPrint('Failed to add topic: $e');
      rethrow;
    }
  }

  /// Update memory strength after flashcard revision with confidence slider.
  Future<void> updateMemoryStrength(String topicId, int newStrength) async {
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

      // Save to local storage
      await _saveTopicsToLocal();
      notifyListeners();
    }
  }

  /// Update topic results after quiz-based revision via backend API.
  Future<void> updateTopicResults(String topicId, List<int> userAnswers, {int? responseTimeSeconds}) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/api/revision/complete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'topic_id': topicId,
          'user_answers': userAnswers,
          'response_time_seconds': responseTimeSeconds,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final topicIndex = _topics.indexWhere((t) => t.id == topicId);
        if (topicIndex >= 0) {
          _topics[topicIndex].memoryStrength = ((data['memory_strength'] ?? 50.0) as num).toInt();
          
          // Update next revision date
          if (data['next_revision_date'] != null) {
            try {
              final dt = DateTime.parse(data['next_revision_date']);
              final now = DateTime.now();
              final diff = dt.difference(now).inDays;
              if (diff <= 0) {
                _topics[topicIndex].nextRevisionDate = 'Today';
                _topics[topicIndex].reviseStatus = 'today';
              } else if (diff == 1) {
                _topics[topicIndex].nextRevisionDate = 'Tomorrow';
                _topics[topicIndex].reviseStatus = 'later';
              } else {
                _topics[topicIndex].nextRevisionDate = 'In $diff days';
                _topics[topicIndex].reviseStatus = 'later';
              }
            } catch (_) {}
          }
          // Save to local storage
          await _saveTopicsToLocal();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Failed to update topic results: $e');
    }
  }

  /// Get quiz for a topic from backend
  Future<Quiz?> fetchQuizForTopic(String topicId) async {
    try {
      final response = await http.get(Uri.parse('$_apiBase/api/revision/quiz/$topicId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> rawQuestions = data['questions'] ?? [];
        
        final questions = rawQuestions.map((q) => QuizQuestion(
          question: q['question'] ?? '',
          options: List<String>.from(q['options'] ?? []),
          correctAnswerIndex: q['correct_answer_index'] ?? 0,
        )).toList();

        return Quiz(
          id: data['quiz_id'] ?? '',
          questions: questions,
        );
      }
    } catch (e) {
      debugPrint('Failed to fetch quiz: $e');
    }
    return null;
  }

  Future<void> uploadNotesAndGenerateQuiz(PlatformFile file, String topicName) async {
    final uri = Uri.parse('$_apiBase/api/notes/upload');
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
      // Save to local storage
      await _saveTopicsToLocal();
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
