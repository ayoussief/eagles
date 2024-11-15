import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  // User information controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _govtIdController = TextEditingController();
  bool _termsAccepted = false;
  String? _selectedLanguage; // Track selected language

  String? profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          _nameController.text = userDoc['name'];
          _emailController.text = userDoc['email'];
          _phoneController.text = userDoc['phoneNumber'] ?? '';
          _govtIdController.text = userDoc['governmentId'] ?? '';
          _termsAccepted = userDoc['termsAccepted'] ?? false;
          profilePictureUrl = userDoc['profilePictureUrl'];
          _selectedLanguage = userDoc['preferredLanguage'] ?? 'en';
          setState(() {});
        }
      }
    } catch (e) {
      print('Failed to load user data: $e');
    }
  }

  Future<void> _updateUserData() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        User? user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'name': _nameController.text,
            'email': _emailController.text,
            'phoneNumber': _phoneController.text,
            'governmentId': _govtIdController.text,
            'profilePictureUrl': profilePictureUrl,
            'termsAccepted': _termsAccepted,
            'preferredLanguage': _selectedLanguage, // Save the language preference
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
        }
      } catch (e) {
        print('Failed to update user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (profilePictureUrl != null)
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(profilePictureUrl!),
                ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _govtIdController,
                decoration: InputDecoration(labelText: 'Government ID Number'),
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your government ID number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _termsAccepted = newValue ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text('I accept the terms and conditions'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLanguage = newValue;
                  });
                },
                items: [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ar', child: Text('Arabic')),
                  // Add more language options as needed
                ],
                decoration: InputDecoration(labelText: 'Select Language'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateUserData,
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
