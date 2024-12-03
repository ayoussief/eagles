import 'package:eagles/constants.dart';
import 'package:eagles/screens/post_details_screen.dart';
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
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listenToNewPosts();
  }

  Future<void> _addComment(String postId, String content) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You must be logged in to comment")),
      );
      return;
    }

    try {
      // Fetch the user's name from the 'users' collection using the userId
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      String userName = userDoc.exists ? userDoc['name'] : 'Anonymous';

      // Add the comment with the username and userId
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'username': userName, // Store username from the 'users' collection
        'userId': user.uid, // Store userId to reference the user
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Comment added successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add comment: $e")),
      );
      print("Error adding comment: $e");
    }
  }

  Future<void> _reactToPost(String postId, String reactionType) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    DocumentReference postRef = _firestore.collection('posts').doc(postId);
    DocumentSnapshot postSnapshot = await postRef.get();

    if (postSnapshot.exists) {
      List likes = postSnapshot['likes'] as List;
      List dislikes = postSnapshot['dislikes'] as List;

      if (reactionType == 'like') {
        if (likes.contains(user.uid)) {
          // Remove like
          likes.remove(user.uid);
        } else {
          // Add like and remove dislike if exists
          likes.add(user.uid);
          dislikes.remove(user.uid);
        }
      } else if (reactionType == 'dislike') {
        if (dislikes.contains(user.uid)) {
          // Remove dislike
          dislikes.remove(user.uid);
        } else {
          // Add dislike and remove like if exists
          dislikes.add(user.uid);
          likes.remove(user.uid);
        }
      }

      // Update the reactions in Firestore
      await postRef.update({
        'likes': likes,
        'dislikes': dislikes,
      });
    }
  }

  Widget _buildCommentsSection(String postId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator()); // Loading indicator
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "No comments yet. Be the first to comment!",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView(
          shrinkWrap:
              true, // Necessary for embedding in another scrollable widget
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                child: Text(
                  data['username'] != null && data['username'].isNotEmpty
                      ? data['username'][0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(data['username'] ?? 'Anonymous'),
              subtitle: Text(data['comment'] ?? ''),
              trailing: Text(
                DateFormat('MMM d, h:mm a').format(
                  (data['timestamp'] as Timestamp).toDate(),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAddCommentSection(String postId) {
    final TextEditingController commentController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: "Add a comment...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send, color: Colors.blue),
            onPressed: () async {
              if (commentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Comment cannot be empty")),
                );
                return;
              }
              await _addComment(postId, commentController.text.trim());
              commentController.clear();
            },
          ),
        ],
      ),
    );
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
                        'likes': [], // List of user IDs
                        'dislikes': [], // List of user IDs
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
        ) ??
        false;

    // Proceed only if the user confirms
    if (confirmDelete) {
      try {
        await _firestore.collection('posts').doc(postId).delete();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Post deleted successfully')));
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
                  Timestamp timestamp = doc['timestamp'];
                  DateTime postDate = timestamp.toDate();
                  String formattedDate =
                      DateFormat('MMMM dd, yyyy, h:mm a').format(postDate);

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
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
                                        icon: Icon(Icons.edit,
                                            color: Colors.black),
                                        onPressed: () => _addOrEditPosts(
                                          context,
                                          postsId: doc.id,
                                          title: doc['title'],
                                          content: doc['content'],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.black),
                                        onPressed: () =>
                                            _deletePost(context, doc.id),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                          Divider(color: Colors.grey[300]),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.thumb_up_alt_outlined,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _reactToPost(doc.id, 'like'),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.thumb_down_alt_outlined,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _reactToPost(doc.id, 'dislike'),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${(doc['likes'] as List).length} Likes, ${(doc['dislikes'] as List).length} Dislikes',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Divider(color: Colors.grey[300]),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Comments',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                StreamBuilder<QuerySnapshot>(
                                  stream: _firestore
                                      .collection('posts')
                                      .doc(doc.id)
                                      .collection('comments')
                                      .orderBy('timestamp', descending: true)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    }

                                    final comments = snapshot.data!.docs;
                                    final displayComments = comments.take(
                                        2); // Show only the first 2 comments

                                    return Column(
                                      children: [
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          itemCount: displayComments.length,
                                          itemBuilder: (context, index) {
                                            final comment = displayComments
                                                .elementAt(index);
                                            Timestamp timestamp =
                                                comment['timestamp'];
                                            DateTime commentDate =
                                                timestamp.toDate();
                                            String commentDateString =
                                                DateFormat(
                                                        'MMM dd, yyyy, h:mm a')
                                                    .format(commentDate);

                                            return ListTile(
                                              leading: CircleAvatar(
                                                child: Text(
                                                  comment['username'][
                                                      0], // First letter of username
                                                ),
                                              ),
                                              title: Text(comment['username']),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(comment['content']),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    commentDateString,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        // "View All Comments" button
                                        if (comments.length > 2)
                                          TextButton(
                                            onPressed: () {
                                              // Navigate to post_details_screen.dart
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PostDetailsScreen(
                                                          postId: doc
                                                              .id), // Pass post ID
                                                ),
                                              );
                                            },
                                            child: Text(
                                              'View All Comments',
                                              style:
                                                  TextStyle(color: Colors.blue),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                SizedBox(height: 10),
                                _buildAddCommentSection(
                                    doc.id), // Add comment section
                              ],
                            ),
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
