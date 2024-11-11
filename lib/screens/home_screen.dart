import 'package:eagles/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if the current user is an admin
  Future<bool> _isAdmin() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.get('role') == 'admin';
  }

  // Function to handle adding or editing posts
  Future<void> _addOrEditPosts(BuildContext context, {String? postsId, String? title, String? content}) async {
    final TextEditingController titleController = TextEditingController(text: title);
    final TextEditingController contentController = TextEditingController(text: content);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(postsId == null ? "Add Post" : "Edit Post"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: contentController,
                decoration: InputDecoration(labelText: "Content"),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                  try {
                    if (postsId == null) {
                      await _firestore.collection('posts').add({
                        'title': titleController.text,
                        'content': contentController.text,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                    } else {
                      await _firestore.collection('posts').doc(postsId).update({
                        'title': titleController.text,
                        'content': contentController.text,
                      });
                    }
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post saved successfully')));
                  } catch (e) {
                    print("Error saving post: ${e.toString()}");
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving post: ${e.toString()}')));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Title and content cannot be empty')));
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Function to delete a post
  void _deletePost(BuildContext context, String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post deleted successfully')));
    } catch (e) {
      print("Error deleting post: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting post: ${e.toString()}')));
    }
  }
@override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final isAdmin = snapshot.data!;

        return Scaffold(
          backgroundColor: KSecondaryColor, // Set page background color
          // appBar: AppBar(title: Text("News")),
          body: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('posts').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("No posts available."));
              }

              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0), // Add padding between items
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, // Set news item background to white
                        borderRadius: BorderRadius.circular(8), // Optional: round corners
                      ),
                      child: ListTile(
                        title: Text(
                          doc['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold, // Different style for title
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          doc['content'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black, // Adjust text color for content
                          ),
                        ),
                        trailing: isAdmin
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.black),
                                    onPressed: () => _addOrEditPosts(
                                      context,
                                      postsId: doc.id,
                                      title: doc['title'],
                                      content: doc['content'],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.black),
                                    onPressed: () => _deletePost(context, doc.id),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          floatingActionButton: isAdmin
              ? FloatingActionButton(
                  onPressed: () => _addOrEditPosts(context),
                  child: Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }
}