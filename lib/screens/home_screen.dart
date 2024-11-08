import 'package:eagles/screens/adminpost_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // for date formatting

class HomeScreen extends StatelessWidget {
  final bool isAdmin;

  HomeScreen({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AdminPostScreen.id);
              },
              child: Text('Add Post'),
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No posts available.'));
              }

              final posts = snapshot.data!.docs;

              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (ctx, index) {
                  final post = posts[index];
                  final timestamp = post['timestamp'] as Timestamp?;
                  final formattedTime = timestamp != null
                      ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())
                      : 'Unknown Time';
                  final writer = post['writer'] ?? 'Anonymous';

                  return Card(
                    margin: EdgeInsets.all(10),
                    elevation: 5,
                    child: ListTile(
                      title: Text(
                        post['title'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post['content']),
                          SizedBox(height: 8),
                          Text('By $writer', style: TextStyle(fontStyle: FontStyle.italic)),
                          Text('Posted on $formattedTime', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      trailing: post['imageUrl'] != null && post['imageUrl'] != ""
                          ? Image.network(post['imageUrl'])
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
