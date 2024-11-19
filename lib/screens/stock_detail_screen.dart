import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StockDetailScreen extends StatefulWidget {
  final Map<String, dynamic> stock;

  const StockDetailScreen({Key? key, required this.stock}) : super(key: key);

  @override
  _StockDetailScreenState createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  late Map<String, dynamic> stock;

  @override
  void initState() {
    super.initState();
    stock = widget.stock;
  }

  void _updateLocalStock(
      int quantity, double entryPrice, double currentPrice, bool isAdding) {
    setState(() {
      if (isAdding) {
        stock['totalQuantity'] += quantity;
        final totalValue = stock['averagePrice'] * stock['totalQuantity'] +
            entryPrice * quantity;
        stock['averagePrice'] = totalValue / stock['totalQuantity'];
      } else {
        stock['totalQuantity'] -= quantity;
      }
      stock['currentPrice'] = currentPrice;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final stockId = stock['stockId'];

    // Stream for user document
    final userStream =
        FirebaseFirestore.instance.collection('users').doc(userId).snapshots();

    // Function to extract stock data
    Map<String, dynamic>? getStockData(Map<String, dynamic> userData) {
      final List<dynamic> stocks = userData['stocks'] ?? [];
      return stocks.firstWhere(
        (item) => item['stockId'] == stockId,
        orElse: () => null,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Stock Details - $stockId'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // Extract user data and stock data
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final stockData = getStockData(userData);

          if (stockData == null) {
            return Center(child: Text('Stock not found.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stock ID: ${stockData['stockId']}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Divider(),
                        Text(
                          'Total Quantity: ${stockData['totalQuantity']}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Average Price: \$${stockData['averagePrice'].toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Current Price: \$${stockData['currentPrice'].toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Profit/Loss: ${_calculateProfitLoss(stockData)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: _isProfit(stockData)
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green),
                                onPressed: () => _showAddStockDialog(context),
                                child: Text('Add More'),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () =>
                                    _showRemoveStockDialog(context),
                                child: Text('Sell Some'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: stockData['history'] == null
                      ? Center(
                          child: Text(
                            'No history available for this stock.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: stockData['history'].length,
                          itemBuilder: (context, index) {
                            // Sort history in descending order of timestamp
                            final history = List.from(stockData['history']);
                            history.sort((a, b) =>
                                DateTime.parse(b['timestamp'])
                                    .compareTo(DateTime.parse(a['timestamp'])));

                            final entry = stockData['history'][index];
                            final action =
                                entry['action'] == 'add' ? 'Added' : 'Removed';
                            final timestamp = DateFormat('yyyy-MM-dd HH:mm')
                                .format(DateTime.parse(entry['timestamp']));

                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
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
                                          '$action ${entry['quantity']} stocks',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: entry['action'] == 'add'
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                        Spacer(),
                                        Text(
                                          timestamp,
                                          style: TextStyle(
                                              fontSize: 14, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Entry Price: \$${entry["entryPrice"].toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'Average Price: \$${entry["averagePrice"].toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'Current Price: \$${entry["currentPrice"].toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

// Helper to calculate profit/loss
  String _calculateProfitLoss(Map<String, dynamic> stockData) {
    double invested = stockData['averagePrice'] * stockData['totalQuantity'];
    double current = stockData['currentPrice'] * stockData['totalQuantity'];
    double profitOrLoss = current - invested;
    return '\$${profitOrLoss.toStringAsFixed(2)}';
  }

// Helper to check if it's a profit
  bool _isProfit(Map<String, dynamic> stockData) {
    double invested = stockData['averagePrice'] * stockData['totalQuantity'];
    double current = stockData['currentPrice'] * stockData['totalQuantity'];
    return current > invested;
  }

  void _showAddStockDialog(BuildContext context) {
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController entryPriceController = TextEditingController();
    final TextEditingController currentPriceController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add More Stocks'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantity to Add'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: entryPriceController,
                decoration: InputDecoration(labelText: 'Entry Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: currentPriceController,
                decoration: InputDecoration(labelText: 'Current Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final int quantity = int.tryParse(quantityController.text) ?? 0;
                final double entryPrice =
                    double.tryParse(entryPriceController.text) ?? 0.0;
                final double currentPrice =
                    double.tryParse(currentPriceController.text) ?? 0.0;

                if (quantity > 0 && entryPrice > 0 && currentPrice > 0) {
                  await _updateStockQuantity(
                      stock, quantity, entryPrice, currentPrice,
                      isAdding: true);
                  _updateLocalStock(quantity, entryPrice, currentPrice, true);
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveStockDialog(BuildContext context) {
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController currentPriceController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sell Some Stocks'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantity to Remove'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: currentPriceController,
                decoration: InputDecoration(labelText: 'Current Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final int quantity = int.tryParse(quantityController.text) ?? 0;
                final double currentPrice =
                    double.tryParse(currentPriceController.text) ?? 0.0;

                if (quantity > 0 && currentPrice > 0) {
                  await _updateStockQuantity(
                      stock, -quantity, stock['averagePrice'], currentPrice,
                      isAdding: false);
                  _updateLocalStock(
                      -quantity, stock['averagePrice'], currentPrice, false);
                  Navigator.pop(context);
                }
              },
              child: Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}

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
