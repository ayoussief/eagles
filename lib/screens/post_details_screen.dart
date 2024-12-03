import 'package:eagles/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PostDetailsScreen extends StatelessWidget {
  final String postId;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PostDetailsScreen({required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details'),
        backgroundColor: KMainColor, // Use KMainColor for the app bar
      ),
      backgroundColor: KSecondaryColor, // Use KSecondaryColor for the body background
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Post not found'));
          }

          final post = snapshot.data!;
          final Timestamp postTimestamp = post['timestamp'];
          final DateTime postDate = postTimestamp.toDate();
          final String formattedPostDate =
              DateFormat('MMM dd, yyyy, h:mm a').format(postDate);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Original Post Section
                Card(
                  margin: EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: Colors.white, // Post background set to white
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['title'] ?? 'No Title',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          formattedPostDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Divider(color: Colors.grey[300]),
                        Text(
                          post['content'] ?? 'No Content',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(post['likes'] as List).length} Likes, ${(post['dislikes'] as List).length} Dislikes',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.thumb_up_alt_outlined,
                                      color: Colors.blue),
                                  onPressed: () => _reactToPost(postId, 'like'),
                                ),
                                IconButton(
                                  icon: Icon(Icons.thumb_down_alt_outlined,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _reactToPost(postId, 'dislike'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Comments Section
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, commentSnapshot) {
                    if (!commentSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final comments = commentSnapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final Timestamp timestamp = comment['timestamp'];
                        final DateTime commentDate = timestamp.toDate();
                        final String commentDateString =
                            DateFormat('MMM dd, yyyy, h:mm a')
                                .format(commentDate);

                        return Card(
                          margin:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          color: Colors.white, // Comment background set to white
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                comment['username'][0].toUpperCase(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              comment['username'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
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
}
