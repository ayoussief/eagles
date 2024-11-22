import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eagles/constants.dart';
import 'package:eagles/main.dart';
import 'package:eagles/screens/stock_detail_screen.dart';
import 'package:eagles/screens/user_history_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import to format date

class ProfileScreen extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;
  final String languageCode;

  ProfileScreen({super.key, required this.languageCode});

  // Calculate balances dynamically
  double calculateUsedBalance(List<dynamic> stocks) {
    return stocks.fold(0.0, (sum, stock) {
      final int quantity = stock['totalQuantity'] ?? 0;
      final double averagePrice = stock['averagePrice'] ?? 0.0;
      return sum + (quantity * averagePrice);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('No user data available.'));
        }

        // Get the user data from Firestore document
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        double totalBalance = userData['totalBalance'] ?? 0.0;
        List<dynamic> stocks = userData['stocks'] ?? [];
        double usedBalance = calculateUsedBalance(stocks);
        double freeBalance = totalBalance - usedBalance;

        // Format the createdAt timestamp
        String createdAt = 'Date not available';
        if (userData['createdAt'] != null) {
          Timestamp timestamp = userData['createdAt'];
          DateTime dateTime = timestamp.toDate();
          createdAt = DateFormat('yyyy-MM-dd').format(dateTime);
        }

        // Subscription dates
        DateTime? subscriptionStart = userData['subscriptionStart'] != null
            ? (userData['subscriptionStart'] as Timestamp).toDate()
            : null;
        DateTime? subscriptionEnd = userData['subscriptionEnd'] != null
            ? (userData['subscriptionEnd'] as Timestamp).toDate()
            : null;

        // Calculate days left in subscription
        int daysLeft = 0;
        if (subscriptionEnd != null) {
          daysLeft = subscriptionEnd.difference(DateTime.now()).inDays;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(translations[languageCode]?['profile'] ?? 'Profile'),
          ),
          body: SingleChildScrollView(
            // Wrapping the entire body with SingleChildScrollView
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: userData['profilePicture'] != null
                        ? NetworkImage(userData['profilePicture'])
                        : null,
                    child: userData['profilePicture'] == null
                        ? Icon(Icons.person, size: 50)
                        : null,
                  ),
                  SizedBox(height: 10),
                  Text(
                    userData['name'] ??
                        translations[languageCode]?['name_not_available'] ??
                        'Name not available',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: KMainColor),
                  ),
                  SizedBox(height: 5),
                  Text(
                    user?.email ??
                        translations[languageCode]?['email_not_available'] ??
                        'Email not available',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '${translations[languageCode]?['role'] ?? 'Role'}: ${userData['role'] ?? translations[languageCode]?['role_not_available'] ?? 'Role not available'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${translations[languageCode]?['joined'] ?? 'Joined'}: $createdAt',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),

                  // Display and edit balances
                  // Total Balance (editable)
                  _buildBalanceRow(
                    translations[languageCode]?['total_balance'] ??
                        'Total Balance',
                    totalBalance,
                    (newValue) => _updateBalance('totalBalance', newValue),
                  ),

                  // Used Balance (read-only)
                  _buildReadOnlyBalanceRow(
                    translations[languageCode]?['used_balance'] ??
                        'Used Balance',
                    usedBalance,
                  ),

                  // Free Balance (read-only)
                  _buildReadOnlyBalanceRow(
                    translations[languageCode]?['free_balance'] ??
                        'Free Balance',
                    freeBalance,
                  ),

                  SizedBox(height: 20),

                  // Subscription Period Section (Read-only)
                  subscriptionStart != null && subscriptionEnd != null
                      ? Column(
                          children: [
                            Text(
                              '${translations[languageCode]?['subscription_period'] ?? 'Subscription Period'}: ${DateFormat('yyyy-MM-dd').format(subscriptionStart)} to ${DateFormat('yyyy-MM-dd').format(subscriptionEnd)}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text(
                                '${translations[languageCode]?['days_left'] ?? 'Days Left'}: $daysLeft',
                                style: TextStyle(color: Colors.red)),
                          ],
                        )
                      : Text(translations[languageCode]
                              ?['subscription_data_not_available'] ??
                          'Subscription data not available.'),
                  SizedBox(height: 20),

                  // Display user's stocks
                  Text(
                    translations[languageCode]?['your_stocks'] ??
                        'Your Stocks:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  // If no stocks, show a message; else, display stock list
                  stocks.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap:
                              true, // Allow ListView to occupy only as much space as needed
                          physics:
                              NeverScrollableScrollPhysics(), // Disable ListView scrolling
                          itemCount: stocks.length,
                          itemBuilder: (context, index) {
                            final stock = stocks[index];

                            // Calculate profitability
                            final int quantity = stock['totalQuantity'] ?? 0;
                            final double averagePrice =
                                stock['averagePrice'] ?? 0.0;
                            final double currentPrice =
                                stock['currentPrice'] ?? 0.0;
                            final double totalInvested =
                                averagePrice * quantity;
                            final double currentValue = currentPrice * quantity;
                            final double profitOrLoss =
                                currentValue - totalInvested;
                            final bool isProfitable = profitOrLoss > 0;

                            return GestureDetector(
                              onTap: () {
                                // Navigate to StockDetailScreen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        StockDetailScreen(stock: stock),
                                  ),
                                );
                              },
                              child: Card(
                                margin: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                elevation:
                                    5, // Add some elevation for a shadow effect
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      12), // Rounded corners
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Stock name
                                      Text(
                                        stock['stockId'] ??
                                            translations[languageCode]
                                                ?['unknown_stock'] ??
                                            'Unknown Stock',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      // Quantity
                                      Text(
                                        '${translations[languageCode]?['quantity'] ?? 'Quantity'}: $quantity',
                                      ),
                                      // Average Price
                                      Text(
                                        '${translations[languageCode]?['average_price'] ?? 'Average Price'}: \$${averagePrice.toStringAsFixed(2)}',
                                      ),
                                      // Current Price
                                      Text(
                                        '${translations[languageCode]?['current_price'] ?? 'Current Price'}: \$${currentPrice.toStringAsFixed(2)}',
                                      ),
                                      // Profit/Loss
                                      Text(
                                        '${translations[languageCode]?['profit_or_loss'] ?? 'Profit/Loss'}: ${isProfitable ? '+' : ''}\$${profitOrLoss.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: isProfitable
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      // Row for Edit and Delete buttons
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit),
                                            onPressed: () =>
                                                _showEditStockDialog(
                                                    context, stock),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete),
                                            onPressed: () =>
                                                _removeStockFromUser(stock),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            translations[languageCode]?['no_stocks_added'] ??
                                'No stocks added yet.',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),

                  SizedBox(
                    height: 20,
                  ),
                  Builder(builder: (context) {
                    double totalProfitOrLoss = stocks.fold(0.0, (sum, stock) {
                      final int quantity = stock['totalQuantity'] ?? 0;
                      final double averagePrice = stock['averagePrice'] ?? 0.0;
                      final double currentPrice = stock['currentPrice'] ?? 0.0;
                      final double totalInvested = averagePrice * quantity;
                      final double currentValue = currentPrice * quantity;
                      return sum + (currentValue - totalInvested);
                    });

                    return Text(
                      '${translations[languageCode]?['total_profit_loss'] ?? 'Total Profit/Loss'}: ${totalProfitOrLoss > 0 ? '+' : ''}\$${totalProfitOrLoss.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            totalProfitOrLoss > 0 ? Colors.green : Colors.red,
                      ),
                    );
                  }),
                  SizedBox(
                    height: 20,
                  ),
                  //user history button

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const UserHistoryScreen()),
                      );
                    },
                    child: const Text(
                      'View Transaction History',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),

                  SizedBox(
                    height: 20,
                  ),
                  // Button to add a new stock
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _showAddStockDialog(context),
                    child: Text(translations[languageCode]?['add_stock'] ??
                        'Add Stock'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to display non-editable balances
  Widget _buildReadOnlyBalanceRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16)),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Balance row for total, used, and free balances
  Widget _buildBalanceRow(
      String title, double balance, Function(double) onSave) {
    final controller = TextEditingController(text: balance.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'Enter amount'),
              ),
            ),
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                final newValue = double.tryParse(controller.text) ?? balance;
                onSave(newValue);
              },
            ),
          ],
        ),
      ],
    );
  }

  // Update balance in Firestore
  Future<void> _updateBalance(String field, double newValue) async {
    if (user == null) return;

    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);
    await userDocRef.update({field: newValue});
  }

  // Function to remove a stock from the user's stocks array in Firestore
  Future<void> _removeStockFromUser(Map<String, dynamic> stock) async {
    if (user == null) return;

    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);
    await userDocRef.update({
      'stocks': FieldValue.arrayRemove([stock])
    });
  }

  // Function to show a dialog to edit a stock's quantity and entry price

  void _showEditStockDialog(BuildContext context, Map<String, dynamic> stock) {
    final quantityController =
        TextEditingController(text: stock['quantity'].toString());
    final entryPriceController =
        TextEditingController(text: stock['entryPrice'].toString());
    final currentPriceController =
        TextEditingController(text: stock['currentPrice'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TextField(
              //   controller: quantityController,
              //   decoration: InputDecoration(labelText: 'Quantity'),
              //   keyboardType: TextInputType.number,
              // ),
              // TextField(
              //   controller: entryPriceController,
              //   decoration: InputDecoration(labelText: 'Entry Price'),
              //   keyboardType: TextInputType.number,
              // ),
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
              onPressed: () {
                final newQuantity =
                    int.tryParse(quantityController.text) ?? stock['quantity'];
                final newEntryPrice =
                    double.tryParse(entryPriceController.text) ??
                        stock['entryPrice'];
                final newCurrentPrice =
                    double.tryParse(currentPriceController.text) ??
                        stock['currentPrice'];

                _updateStockInUser(
                    stock, newQuantity, newEntryPrice, newCurrentPrice);

                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Function to update a stock's quantity and entry price in Firestore

  Future<void> _updateStockInUser(Map<String, dynamic> stock, int newQuantity,
      double newEntryPrice, double newCurrentPrice) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);

    try {
      final snapshot = await userDocRef.get();
      final userData = snapshot.data() as Map<String, dynamic>;
      final List<dynamic> stocks = userData['stocks'] ?? [];

      // Find the existing stock entry by stockId
      Map<String, dynamic>? existingStock = stocks.firstWhere(
          (s) => s['stockId'] == stock['stockId'],
          orElse: () => null);

      if (existingStock != null) {
        // Calculate total quantity for all trades of the stock
        int totalQuantity = 0;
        double totalValue = 0.0;
        for (var trade in stocks) {
          if (trade['stockId'] == stock['stockId']) {
            totalQuantity += trade['quantity'] as int; // Cast quantity to int
            totalValue += (trade['quantity'] as int) *
                trade['entryPrice']; // Cast quantity to int
          }
        }

        // Calculate the new average price
        double newAveragePrice = totalValue / totalQuantity;

        // Remove old stock entry from Firestore
        await userDocRef.update({
          'stocks': FieldValue.arrayRemove([existingStock])
        });

        // Update stock data
        existingStock['quantity'] = totalQuantity;
        existingStock['entryPrice'] = newAveragePrice;
        existingStock['currentPrice'] =
            newCurrentPrice; // Update the current price with the new value

        // Add updated stock entry back to Firestore
        await userDocRef.update({
          'stocks': FieldValue.arrayUnion([existingStock])
        });

        print("Stock updated successfully: $stock");
      } else {
        print("Stock not found: ${stock['stockId']}");
      }
    } catch (e) {
      print("Error updating stock: $e");
    }
  }

// Function to show a dialog to add a new stock

  Future<void> _showAddStockDialog(BuildContext context) async {
    final TextEditingController stockIdController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController entryPriceController = TextEditingController();
    final TextEditingController currentPriceController =
        TextEditingController(); // For current price input

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Stock'),
          content: Column(
            children: [
              TextField(
                controller: stockIdController,
                decoration: InputDecoration(labelText: 'Stock ID'),
              ),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
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
                String stockId = stockIdController.text;
                int quantity = int.tryParse(quantityController.text) ?? 0;
                double entryPrice =
                    double.tryParse(entryPriceController.text) ?? 0.0;
                double currentPrice =
                    double.tryParse(currentPriceController.text) ?? 0.0;

                if (stockId.isNotEmpty &&
                    quantity > 0 &&
                    entryPrice > 0 &&
                    currentPrice > 0) {
                  await _addStockToUser(
                      stockId, quantity, entryPrice, currentPrice);
                  Navigator.pop(context);
                }
              },
              child: Text('Add Stock'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addStockToUser(String stockId, int quantity, double entryPrice,
      double currentPrice) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || stockId.isEmpty || quantity <= 0) return;

    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final snapshot = await userDocRef.get();
    final userData = snapshot.data() as Map<String, dynamic>;
    final List<dynamic> stocks = userData['stocks'] ?? [];

    // Find the existing stock
    Map<String, dynamic>? existingStock = stocks
        .firstWhere((stock) => stock['stockId'] == stockId, orElse: () => null);

    if (existingStock != null) {
      // Update stock data
      int newTotalQuantity = existingStock['totalQuantity'] + quantity;
      double newTotalValue =
          existingStock['totalValue'] + (quantity * entryPrice);
      double newAveragePrice = newTotalValue / newTotalQuantity;

      // Remove the old stock entry
      await userDocRef.update({
        'stocks': FieldValue.arrayRemove([existingStock])
      });

      // Add updated stock entry
      existingStock['totalQuantity'] = newTotalQuantity;
      existingStock['totalValue'] = newTotalValue;
      existingStock['averagePrice'] = newAveragePrice;
      existingStock['currentPrice'] = currentPrice; // Store current price

      await userDocRef.update({
        'stocks': FieldValue.arrayUnion([existingStock])
      });
    } else {
      // Add new stock entry
      await userDocRef.update({
        'stocks': FieldValue.arrayUnion([
          {
            'stockId': stockId,
            'quantity': quantity,
            'entryPrice': entryPrice,
            'totalQuantity': quantity,
            'totalValue': quantity * entryPrice,
            'averagePrice': entryPrice,
            'currentPrice': currentPrice, // Set this dynamically
          }
        ])
      });
    }
  }
}
