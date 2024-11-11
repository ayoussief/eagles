import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPostScreen extends StatefulWidget {

  static String id = 'AdminPostScreen';
  @override
  _AdminPostScreenState createState() => _AdminPostScreenState();
}

class _AdminPostScreenState extends State<AdminPostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageController = TextEditingController(); // optional for image URL

  Future<void> _submitPost() async {
    String title = _titleController.text.trim();
    String content = _contentController.text.trim();
    String imageUrl = _imageController.text.trim();

    if (title.isEmpty || content.isEmpty) return;

    try {
      // Add post to Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'title': title,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl, // optional
      });

      // Show confirmation and clear the form
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post added')));
      _titleController.clear();
      _contentController.clear();
      _imageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: 'Content'),
              maxLines: 5,
            ),
            TextField(
              controller: _imageController,
              decoration: InputDecoration(labelText: 'Image URL (Optional)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitPost,
              child: Text('Submit Post'),
            ),
          ],
        ),
      ),
    );
  }
}