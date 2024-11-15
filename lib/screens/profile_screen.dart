import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eagles/constants.dart';
import 'package:eagles/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import to format date

class ProfileScreen extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;
  final String languageCode;

  ProfileScreen({super.key, required this.languageCode});

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

        // Format the createdAt timestamp
        String createdAt = 'Date not available';
        if (userData['createdAt'] != null) {
          Timestamp timestamp = userData['createdAt'];
          DateTime dateTime = timestamp.toDate();
          createdAt = DateFormat('yyyy-MM-dd').format(dateTime);
        }

        // Extract balances
        double totalBalance = userData['totalBalance'] ?? 0.0;
        double usedBalance = userData['usedBalance'] ?? 0.0;
        double freeBalance = userData['freeBalance'] ?? 0.0;

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

        // Extract user's stocks
        List<dynamic> stocks = userData['stocks'] ?? [];

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
                  _buildBalanceRow(
                      translations[languageCode]?['total_balance'] ??
                          'Total Balance',
                      totalBalance,
                      (newValue) => _updateBalance('totalBalance', newValue)),
                  _buildBalanceRow(
                      translations[languageCode]?['used_balance'] ??
                          'Used Balance',
                      usedBalance,
                      (newValue) => _updateBalance('usedBalance', newValue)),
                  _buildBalanceRow(
                      translations[languageCode]?['free_balance'] ??
                          'Free Balance',
                      freeBalance,
                      (newValue) => _updateBalance('freeBalance', newValue)),

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
                            return ListTile(
                              title: Text(stock['stockId'] ??
                                  translations[languageCode]
                                      ?['unknown_stock'] ??
                                  'Unknown Stock'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${translations[languageCode]?['quantity'] ?? 'Quantity'}: ${stock['quantity']}'),
                                  Text(
                                      '${translations[languageCode]?['entry_price'] ?? 'Entry Price'}: \$${stock['entryPrice']}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () =>
                                        _showEditStockDialog(context, stock),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () =>
                                        _removeStockFromUser(stock),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Text(translations[languageCode]?['no_stocks_added'] ??
                          'No stocks added yet.'),
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

  // Function to add a new stock to the user's stocks array in Firestore
  Future<void> _addStockToUser(
      String stockId, int quantity, double entryPrice) async {
    if (user == null || stockId.isEmpty || quantity <= 0) return;

    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);
    await userDocRef.update({
      'stocks': FieldValue.arrayUnion([
        {'stockId': stockId, 'quantity': quantity, 'entryPrice': entryPrice}
      ])
    });
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                _updateStockInUser(stock, newQuantity, newEntryPrice);
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
  Future<void> _updateStockInUser(
      Map<String, dynamic> stock, int newQuantity, double newEntryPrice) async {
    if (user == null) return;

    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);

    // Remove old stock entry
    await userDocRef.update({
      'stocks': FieldValue.arrayRemove([stock])
    });

    // Add updated stock entry
    stock['quantity'] = newQuantity;
    stock['entryPrice'] = newEntryPrice;

    await userDocRef.update({
      'stocks': FieldValue.arrayUnion([stock])
    });
  }
}

// Function to show a dialog to add a new stock
void _showAddStockDialog(BuildContext context) {
  final stockIdController = TextEditingController();
  final quantityController = TextEditingController();
  final entryPriceController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Add New Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final stockId = stockIdController.text;
              final quantity = int.tryParse(quantityController.text) ?? 0;
              final entryPrice =
                  double.tryParse(entryPriceController.text) ?? 0.0;
              _addStockToUser(stockId, quantity, entryPrice);
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      );
    },
  );
}

// Function to add a new stock to the user's stocks array in Firestore
Future<void> _addStockToUser(
    String stockId, int quantity, double entryPrice) async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null || stockId.isEmpty || quantity <= 0) return;

  final userDocRef =
      FirebaseFirestore.instance.collection('users').doc(user!.uid);
  await userDocRef.update({
    'stocks': FieldValue.arrayUnion([
      {'stockId': stockId, 'quantity': quantity, 'entryPrice': entryPrice}
    ])
  });
}
