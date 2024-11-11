import 'package:cloud_firestore/cloud_firestore.dart';
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
    subscriptionStart = widget.userData['subscriptionStart']?.toDate() ?? DateTime.now();
    subscriptionEnd = widget.userData['subscriptionEnd']?.toDate() ?? DateTime.now();
  }

  // Function to format dates
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
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        isStart ? 'subscriptionStart' : 'subscriptionEnd': Timestamp.fromDate(picked),
      });
    }
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

            Text('Balance Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

            Text('Subscription', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

            Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              title: Text("Phone Number"),
              trailing: Text(getValue(widget.userData['phoneNumber'])),
            ),
            ListTile(
              title: Text("Government ID"),
              trailing: Text(getValue(widget.userData['governmentId'])),
            ),
            Divider(height: 32, thickness: 1.5),

            if (stocks.isNotEmpty) ...[
              Text('Stocks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...stocks.map((stock) {
                return ListTile(
                  title: Text("Stock ID: ${stock['stockId']}"),
                  subtitle: Text("Quantity: ${stock['quantity']}, Entry Price: ${stock['entryPrice']}"),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}