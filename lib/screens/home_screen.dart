import 'package:eagles/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentSnapshot? _lastPostSnapshot;

  @override
  void initState() {
    super.initState();
    _listenToNewPosts();
  }

  Future<void> _listenToNewPosts() async {
    _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final docs = snapshot.docs;
      if (docs.isNotEmpty &&
          _lastPostSnapshot != null &&
          docs.first.id != _lastPostSnapshot!.id) {
        final newPost = docs.first;
        _showNotification(newPost['title'], newPost['content']);
      }
      _lastPostSnapshot = docs.isNotEmpty ? docs.first : null;
    });
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'new_post_channel',
      'New Posts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  Future<bool> _isAdmin() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();
    return userDoc.get('role') == 'admin';
  }

  Future<void> _addOrEditPosts(BuildContext context,
      {String? postsId, String? title, String? content}) async {
    final TextEditingController titleController =
        TextEditingController(text: title);
    final TextEditingController contentController =
        TextEditingController(text: content);

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
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
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
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Post saved successfully')));
                  } catch (e) {
                    print("Error saving post: ${e.toString()}");
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error saving post: ${e.toString()}')));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Title and content cannot be empty')));
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _deletePost(BuildContext context, String postId) async {
  // Show a confirmation dialog before deleting
  bool confirmDelete = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Delete Post'),
        content: Text('Are you sure you want to delete this post?'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(false); // Cancel the action
            },
          ),
          TextButton(
            child: Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop(true); // Confirm the deletion
            },
          ),
        ],
      );
    },
  ) ?? false;

  // Proceed only if the user confirms
  if (confirmDelete) {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post deleted successfully')));
    } catch (e) {
      print("Error deleting post: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: ${e.toString()}')));
    }
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
        backgroundColor: KSecondaryColor,
        body: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('posts')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No posts available."));
            }

            return ListView(
              children: snapshot.data!.docs.map((doc) {
                // Extract and format the date
                Timestamp timestamp = doc['timestamp'];
                DateTime postDate = timestamp.toDate();
                String formattedDate = DateFormat('MMMM dd, yyyy, h:mm a').format(postDate);

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            doc['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            doc['content'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
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
                      ],
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