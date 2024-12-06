import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String userId;

  UserDetailScreen({required this.userData, required this.userId});

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late DateTime subscriptionStart;
  late DateTime subscriptionEnd;

  @override
  void initState() {
    super.initState();
    subscriptionStart =
        widget.userData['subscriptionStart']?.toDate() ?? DateTime.now();
    subscriptionEnd =
        widget.userData['subscriptionEnd']?.toDate() ?? DateTime.now();
  }

  String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Function to pick a date
  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? subscriptionStart : subscriptionEnd,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          subscriptionStart = picked;
        } else {
          subscriptionEnd = picked;
        }
      });
      // Update Firestore with new date
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        isStart ? 'subscriptionStart' : 'subscriptionEnd':
            Timestamp.fromDate(picked),
      });
    }
  }

  Future<void> _addComment(String stockId) async {
    TextEditingController commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Comment for Stock $stockId'),
          content: TextField(
            controller: commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter your comment',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final comment = commentController.text.trim();
                if (comment.isNotEmpty) {
                  final timestamp = Timestamp.now();

                  // Get current user name from FirebaseAuth or Firestore
                  final currentUser = FirebaseAuth.instance.currentUser;
                  String userName = "Unknown User"; // Default user name

                  if (currentUser != null) {
                    // Fetch the user's name from Firestore if available
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .get();
                    userName = userDoc['name'] ??
                        currentUser.displayName ??
                        "Unknown User";
                  }

                  // Update Firestore
                  final userRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userId);
                  await userRef.update({
                    'stocks': widget.userData['stocks'].map((stock) {
                      if (stock['stockId'] == stockId) {
                        stock['comments'] = (stock['comments'] ?? [])
                          ..add({
                            'text': comment,
                            'timestamp': timestamp,
                            'userName':
                                userName, // Use the dynamic user name here
                          });
                      }
                      return stock;
                    }).toList(),
                  });

                  // Update UI
                  setState(() {
                    widget.userData['stocks'] = widget.userData['stocks'];
                  });

                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String getValue(dynamic value) {
    return value?.toString() ?? 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final stocks = widget.userData['stocks'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userData['name'] ?? 'User Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Center(
              child: CircleAvatar(
                radius: 40,
                child: Text(
                  (widget.userData['name'] ?? 'U')[0].toUpperCase(),
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                backgroundColor: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                getValue(widget.userData['name']),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                getValue(widget.userData['email']),
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            Divider(height: 32, thickness: 1.5),

            Text('Balance Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              title: Text("Total Balance"),
              trailing: Text(getValue(widget.userData['totalBalance'])),
            ),
            ListTile(
              title: Text("Used Balance"),
              trailing: Text(getValue(widget.userData['usedBalance'])),
            ),
            ListTile(
              title: Text("Free Balance"),
              trailing: Text(getValue(widget.userData['freeBalance'])),
            ),
            Divider(height: 32, thickness: 1.5),

            Text('Subscription',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              title: Text("Subscription Start"),
              trailing: TextButton(
                onPressed: () => _pickDate(context, true),
                child: Text(formatDate(subscriptionStart)),
              ),
            ),
            ListTile(
              title: Text("Subscription End"),
              trailing: TextButton(
                onPressed: () => _pickDate(context, false),
                child: Text(formatDate(subscriptionEnd)),
              ),
            ),
            Divider(height: 32, thickness: 1.5),

            Text('Contact Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              title: Text("Phone Number"),
              trailing: Text(getValue(widget.userData['phoneNumber'])),
            ),
            ListTile(
              title: Text("Government ID"),
              trailing: Text(getValue(widget.userData['governmentId'])),
            ),
            Divider(height: 32, thickness: 1.5),

            // Stocks and Comments
            if (stocks.isNotEmpty) ...[
              Text(
                'Stocks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...stocks.map((stock) {
                final comments = stock['comments'] as List<dynamic>? ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text("Stock ID: ${stock['stockId']}"),
                      subtitle: Text(
                        "Quantity: ${stock['totalQuantity']}, Entry Price: ${stock['averagePrice']}",
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.add_comment),
                        onPressed: () => _addComment(stock['stockId']),
                      ),
                    ),
                    if (comments.isNotEmpty)
                      ...comments.map((comment) {
                        final userName = comment['userName'] ?? 'Unknown User';
                        final timestamp =
                            (comment['timestamp'] as Timestamp).toDate();
                        final formattedTimestamp =
                            "${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}";

                        return Padding(
                          padding:
                              const EdgeInsets.only(left: 16.0, bottom: 8.0),
                          child: Card(
                            elevation: 2,
                            margin: EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(8),
                              leading: CircleAvatar(
                                child: Text(userName[0].toUpperCase()),
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                              title: Text(userName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment['text'],
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    formattedTimestamp,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
