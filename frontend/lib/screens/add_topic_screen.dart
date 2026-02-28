import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/topics_provider.dart';

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
  String _notes = '';

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
                'Enter the details of the concept you want to master.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              
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
              
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Optional Notes',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 50.0),
                    child: Icon(Icons.note, color: theme.primaryColor),
                  ),
                ),
                maxLines: 3,
                onSaved: (val) => _notes = val ?? '',
              ),
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      
                      // Add via Provider
                      Provider.of<TopicsProvider>(context, listen: false)
                          .addTopic(_name, _subject, _difficulty, _confidence);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Topic Added Successfully!'),
                          backgroundColor: theme.primaryColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
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
