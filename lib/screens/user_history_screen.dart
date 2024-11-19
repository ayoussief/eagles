import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserHistoryScreen extends StatelessWidget {
  const UserHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Transaction History'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> globalHistory = userData['globalHistory'] ?? [];

          if (globalHistory.isEmpty) {
            return const Center(
              child: Text(
                'No transactions found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Sort the history by timestamp in descending order
          globalHistory.sort((a, b) =>
              DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));

          return ListView.builder(
            itemCount: globalHistory.length,
            itemBuilder: (context, index) {
              final historyEntry = globalHistory[index];
              final action = historyEntry['action'] == 'add' ? 'Added' : 'Removed';
              final timestamp = DateFormat('yyyy-MM-dd HH:mm')
                  .format(DateTime.parse(historyEntry['timestamp']));

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$action ${historyEntry['quantity']} stocks',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: historyEntry['action'] == 'add'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          Spacer(),
                          Text(
                            timestamp,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Stock ID: ${historyEntry['stockId']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Entry Price: \$${historyEntry['entryPrice'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Average Price: \$${historyEntry['averagePrice'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Current Price: \$${historyEntry['currentPrice'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
