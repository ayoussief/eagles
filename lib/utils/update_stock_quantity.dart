import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> _updateStockQuantity(
  Map<String, dynamic> stock,
  int quantityDelta,
  double entryPrice,
  double currentPrice,
  {required bool isAdding}) async {
  
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

  // Fetch user data
  final snapshot = await userDoc.get();
  final userData = snapshot.data() as Map<String, dynamic>;
  final stocks = userData['stocks'] as List<dynamic>;

  final stockIndex = stocks.indexWhere((item) => item['stockId'] == stock['stockId']);
  if (stockIndex == -1) return;

  final stockData = stocks[stockIndex];

  // Save the current total quantity
  final previousTotalQuantity = stockData['totalQuantity'];

  // Update the total quantity
  stockData['totalQuantity'] += quantityDelta;

  if (isAdding) {
    // Recalculate the average price
    stockData['averagePrice'] = 
        ((stockData['averagePrice'] * previousTotalQuantity) + (entryPrice * quantityDelta)) / stockData['totalQuantity'];
  }

  // Update the current price
  stockData['currentPrice'] = currentPrice;

  // Add entry to the stock's history
  final stockHistoryEntry = {
    "action": isAdding ? "add" : "remove",
    "quantity": quantityDelta.abs(),
    "entryPrice": entryPrice,
    "averagePrice": stockData['averagePrice'],
    "currentPrice": currentPrice,
    "timestamp": DateTime.now().toIso8601String(),
  };

  if (stockData['history'] == null) {
    stockData['history'] = [];
  }
  stockData['history'].add(stockHistoryEntry);

  // Add entry to the user's global history
  final globalHistoryEntry = {
    "stockId": stock['stockId'],
    "action": isAdding ? "add" : "remove",
    "quantity": quantityDelta.abs(),
    "entryPrice": entryPrice,
    "averagePrice": stockData['averagePrice'],
    "currentPrice": currentPrice,
    "timestamp": DateTime.now().toIso8601String(),
  };

  if (userData['globalHistory'] == null) {
    userData['globalHistory'] = [];
  }
  userData['globalHistory'].add(globalHistoryEntry);

  // Update Firestore
  stocks[stockIndex] = stockData;
  await userDoc.update({
    'stocks': stocks,
    'globalHistory': userData['globalHistory'],
  });
}
