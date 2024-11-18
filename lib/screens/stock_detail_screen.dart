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
    return Scaffold(
      appBar: AppBar(
        title: Text('Stock Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock ID: ${stock['stockId']}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Total Quantity: ${stock['totalQuantity']}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Average Price: \$${stock['averagePrice'].toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Current Price: \$${stock['currentPrice'].toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showAddStockDialog(context),
                    child: Text('Add More Stocks'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showRemoveStockDialog(context),
                    child: Text('Sell Some Stocks'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                      stock['stockId'], quantity, entryPrice, currentPrice,
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
                  await _updateStockQuantity(stock['stockId'], quantity,
                      stock['averagePrice'], currentPrice,
                      isAdding: false);
                  _updateLocalStock(
                      quantity, stock['averagePrice'], currentPrice, false);
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
    String stockId, int quantity, double entryPrice, double currentPrice,
    {required bool isAdding}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final userDocRef =
      FirebaseFirestore.instance.collection('users').doc(user.uid);

  try {
    final snapshot = await userDocRef.get();
    if (!snapshot.exists) {
      print('User document does not exist.');
      return;
    }

    final userData = snapshot.data() as Map<String, dynamic>;
    final List<dynamic> stocks = userData['stocks'] ?? [];

    // Find the stock entry to update
    int stockIndex = stocks.indexWhere((s) => s['stockId'] == stockId);
    if (stockIndex == -1) {
      print('Stock with ID $stockId not found.');
      return;
    }

    Map<String, dynamic> stock = Map<String, dynamic>.from(stocks[stockIndex]);

    int currentQuantity = stock['totalQuantity'] ?? 0;
    double currentTotalValue = stock['averagePrice'] * currentQuantity;

    if (!isAdding && quantity > currentQuantity) {
      print('Error: Attempting to remove more stocks than available.');
      return;
    }

    // Calculate updated values
    final int newQuantity =
        isAdding ? currentQuantity + quantity : currentQuantity - quantity;

    final double updatedTotalValue = isAdding
        ? currentTotalValue + (quantity * entryPrice)
        : currentTotalValue - (quantity * stock['averagePrice']);

    final double newAveragePrice =
        newQuantity > 0 ? updatedTotalValue / newQuantity : 0.0;

    // Update stock fields
    stock['totalQuantity'] = newQuantity;
    stock['totalValue'] = updatedTotalValue;
    stock['averagePrice'] = newAveragePrice;
    stock['currentPrice'] = currentPrice;

    // Replace the stock in the list
    stocks[stockIndex] = stock;

    // Update Firestore
    await userDocRef.update({'stocks': stocks});

    print(
        '${isAdding ? 'Added' : 'Removed'} $quantity stocks. New total: $newQuantity');
  } catch (e) {
    print('Error updating stock quantity: $e');
  }
}
