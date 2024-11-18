import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text('Stock Details - $stockId'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // Extract stock data from the user's stocks array
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> stocks = userData['stocks'] ?? [];
          final stockData = stocks.firstWhere(
            (item) => item['stockId'] == stockId,
            orElse: () => null,
          );

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
  double currentPrice, {
  required bool isAdding,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

  // Fetch user data
  final snapshot = await userDoc.get();
  final userData = snapshot.data() as Map<String, dynamic>;
  final stocks = userData['stocks'] as List<dynamic>;

  // Find the stock
  final stockIndex =
      stocks.indexWhere((item) => item['stockId'] == stock['stockId']);
  if (stockIndex == -1) return;

  final stockData = stocks[stockIndex];
  stockData['totalQuantity'] += quantityDelta;

  // Recalculate the average price
  if (isAdding) {
    // If adding, update the average price accordingly
    stockData['averagePrice'] =
        ((stockData['averagePrice'] * stockData['totalQuantity']) +
                (entryPrice * quantityDelta)) /
            stockData['totalQuantity'];
  } else {
    // If removing, simply update the total quantity without changing average price
    stockData['averagePrice'] = stockData['averagePrice'];
  }

  stockData['currentPrice'] = currentPrice;

  // Update Firestore
  stocks[stockIndex] = stockData;
  await userDoc.update({'stocks': stocks});
}
