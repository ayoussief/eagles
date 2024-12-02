import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId;

  PostDetailsScreen({required this.postId});

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  bool showAllComments = false; // Flag to show all comments
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _commentController = TextEditingController(); // Controller for the comment text field
  String? _userId = 'user123'; // Simulate user ID (Replace with actual user authentication logic)
  String? _username = 'John Doe'; // Simulate username (Replace with actual username from auth)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Post Details")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Your post content here

            // Comments section
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
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;
                int displayedCommentsCount = showAllComments ? comments.length : 1; // Show only 1 initially

                return Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: displayedCommentsCount,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        Timestamp timestamp = comment['timestamp'];
                        DateTime commentDate = timestamp.toDate();
                        String commentDateString = DateFormat('MMM dd, yyyy, h:mm a').format(commentDate);

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(comment['username'][0]), // First letter of username
                          ),
                          title: Text(comment['username']), // Display username
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                    // Show "Show All" button if there are more comments to show
                    if (!showAllComments && comments.length > 1)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            showAllComments = true; // Show all comments
                          });
                        },
                        child: Text('Show All Comments'),
                      ),
                  ],
                );
              },
            ),

            // Add new comment section
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  // Comment input field
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        labelText: 'Add a comment...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  // Submit button
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to handle adding a comment
  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      return; // Do nothing if the comment is empty
    }

    try {
      // Add the comment to Firestore
      await _firestore.collection('posts').doc(widget.postId).collection('comments').add({
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _userId, // Replace with actual user ID
        'username': _username, // Replace with actual username
      });

      // Clear the text field after submitting
      _commentController.clear();
    } catch (e) {
      print('Error adding comment: $e');
    }
  }
}
