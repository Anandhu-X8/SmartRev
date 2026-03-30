import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../services/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _schoolController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _profileExists = false;
  bool _isEditMode = false;
  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.userId;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final doc = await firebaseService.firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final hasProfile = (data['firstName'] ?? '').toString().isNotEmpty;
        if (hasProfile) {
          _profileData = data;
          _profileExists = true;
          _isEditMode = false;
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _schoolController.text = data['school'] ?? '';
        } else {
          _profileExists = false;
          _isEditMode = true;
          final displayName = authProvider.username;
          final parts = displayName.split(' ');
          _firstNameController.text = parts.first;
          if (parts.length > 1) {
            _lastNameController.text = parts.sublist(1).join(' ');
          }
        }
      } else {
        _profileExists = false;
        _isEditMode = true;
        final displayName = authProvider.username;
        final parts = displayName.split(' ');
        _firstNameController.text = parts.first;
        if (parts.length > 1) {
          _lastNameController.text = parts.sublist(1).join(' ');
        }
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      _isEditMode = true;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.userId;
    if (uid == null) return;

    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final data = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'school': _schoolController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await firebaseService.firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _profileData = {
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'age': int.tryParse(_ageController.text.trim()) ?? 0,
            'school': _schoolController.text.trim(),
          };
          _profileExists = true;
          _isEditMode = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_profileExists ? 'Profile updated successfully!' : 'Profile saved successfully!'),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final firebaseService = Provider.of<FirebaseService>(context, listen: false);
              await firebaseService.signOut();
              authProvider.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEditMode
              ? _buildEditForm(theme, authProvider)
              : _buildProfileView(theme, authProvider),
    );
  }

  Widget _buildProfileView(ThemeData theme, AuthProvider authProvider) {
    final firstName = _profileData['firstName'] ?? '';
    final lastName = _profileData['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final age = _profileData['age']?.toString() ?? '';
    final school = _profileData['school'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Avatar
          CircleAvatar(
            radius: 55,
            backgroundColor: theme.colorScheme.secondary,
            child: Text(
              firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: theme.primaryColor),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fullName.isNotEmpty ? fullName : authProvider.username,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 32),

          // Profile details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDetailRow(Icons.person_outline, 'First Name', firstName, theme),
                const Divider(height: 32),
                _buildDetailRow(Icons.person_outline, 'Last Name', lastName, theme),
                const Divider(height: 32),
                _buildDetailRow(Icons.cake_outlined, 'Age', age, theme),
                const Divider(height: 32),
                _buildDetailRow(Icons.school_outlined, 'School / College', school, theme),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Edit profile button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _isEditMode = true);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile', style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: theme.primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: theme.primaryColor, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.isNotEmpty ? value : '-',
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditForm(ThemeData theme, AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.secondary,
              child: Icon(Icons.person, size: 50, color: theme.primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              authProvider.username,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 32),

            // First Name
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name',
                prefixIcon: Icon(Icons.badge_outlined, color: theme.primaryColor),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Last Name
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                prefixIcon: Icon(Icons.badge_outlined, color: theme.primaryColor),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Age
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Age',
                prefixIcon: Icon(Icons.cake_outlined, color: theme.primaryColor),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final age = int.tryParse(v.trim());
                if (age == null || age < 1 || age > 120) return 'Enter a valid age';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // School/College
            TextFormField(
              controller: _schoolController,
              decoration: InputDecoration(
                labelText: 'School / College',
                prefixIcon: Icon(Icons.school_outlined, color: theme.primaryColor),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _profileExists ? 'Update Profile' : 'Save Profile',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),

            // Cancel button (only show if profile already exists)
            if (_profileExists) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditMode = false;
                      // Restore form values from saved data
                      _firstNameController.text = _profileData['firstName'] ?? '';
                      _lastNameController.text = _profileData['lastName'] ?? '';
                      _ageController.text = _profileData['age']?.toString() ?? '';
                      _schoolController.text = _profileData['school'] ?? '';
                    });
                  },
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
