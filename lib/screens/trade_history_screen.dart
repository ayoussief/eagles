import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TradeHistoryScreen extends StatelessWidget {
  final String userId;

  TradeHistoryScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trade History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trades')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No trades found.'),
            );
          }

          final trades = snapshot.data!.docs;

          return ListView.builder(
            itemCount: trades.length,
            itemBuilder: (context, index) {
              final trade = trades[index].data() as Map<String, dynamic>;
              final timestamp = trade['timestamp'] as Timestamp?;
              final dateTime =
                  timestamp != null ? timestamp.toDate() : DateTime.now();

              return ListTile(
                title: Text('${trade['stockId']} - ${trade['tradeType']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Quantity: ${trade['quantity']} @ \$${trade['entryPrice'].toStringAsFixed(2)}'),
                    Text('Date: ${DateFormat.yMMMd().format(dateTime)}'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
