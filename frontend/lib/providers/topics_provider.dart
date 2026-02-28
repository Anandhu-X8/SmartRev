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

// Dummy Model for frontend
class Topic {
  final String id;
  final String name;
  final String subject;
  int memoryStrength;
  String nextRevisionDate;
  Quiz? quiz; // Link quiz to topic
  bool isAiGenerated;

  Topic({
    required this.id,
    required this.name,
    required this.subject,
    required this.memoryStrength,
    required this.nextRevisionDate,
    this.quiz,
    this.isAiGenerated = false,
  });
}

class TopicsProvider extends ChangeNotifier {
  final List<Topic> _topics = [
    Topic(id: '1', name: 'Flutter State Management', subject: 'Programming', memoryStrength: 45, nextRevisionDate: 'Today'),
    Topic(id: '2', name: 'Python Decorators', subject: 'Programming', memoryStrength: 60, nextRevisionDate: 'Today'),
    Topic(id: '3', name: 'Spaced Repetition Math', subject: 'Algorithms', memoryStrength: 80, nextRevisionDate: 'Tommorrow'),
  ];

  List<Topic> get topics => _topics;
  
  List<Topic> get todaysRevisionQueue {
    return _topics.where((t) => t.nextRevisionDate == 'Today').toList();
  }

  void addTopic(String name, String subject, String difficulty, double confidence) {
    // Determine initial strength based on confidence (1-5) dummy logic
    int strength = (confidence * 20).toInt();
    
    // Instantly generate a 5-question dummy quiz for immediate revision
    final dummyQuiz = Quiz(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      questions: List.generate(5, (index) => QuizQuestion(
        question: 'Dummy Question ${index + 1} for $name?',
        options: ['Option A', 'Option B', 'Option C', 'Option D'],
        correctAnswerIndex: index % 4,
      )),
    );
    
    final newTopic = Topic(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      subject: subject,
      memoryStrength: strength,
      nextRevisionDate: 'Today', // Force new topics to queue for testing
      quiz: dummyQuiz,
    );
    
    _topics.add(newTopic);
    notifyListeners(); // This is the key for immediate dashboard updates
  }

  void updateTopicResults(String topicId, int correctAnswers, int memoryStrengthChange) {
    final topicIndex = _topics.indexWhere((t) => t.id == topicId);
    if (topicIndex >= 0) {
      final topic = _topics[topicIndex];
      // Update memory strength with bounds
      int newStrength = topic.memoryStrength + memoryStrengthChange;
      newStrength = newStrength.clamp(0, 100);
      
      topic.memoryStrength = newStrength;
      
      // If performed well, move to tomorrow
      if (correctAnswers >= 4) {
        topic.nextRevisionDate = 'Tomorrow';
      } else {
        topic.nextRevisionDate = 'Today';
      }
      
      notifyListeners();
    }
  }

  Future<void> uploadNotesAndGenerateQuiz(PlatformFile file, String topicName) async {
    // 127.0.0.1 can sometimes cause issues in Flutter web / chrome. Using localhost.
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
