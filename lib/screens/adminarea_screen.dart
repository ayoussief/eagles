import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'userdetail_screen.dart'; // Ensure this points to your UserDetailScreen file

class AdminAreaScreen extends StatefulWidget {
  static String id = 'AdminAreaScreen';

  @override
  _AdminAreaScreenState createState() => _AdminAreaScreenState();
}

class _AdminAreaScreenState extends State<AdminAreaScreen> {
  int totalUsers = 0;
  int activeSubscribers = 0;
  int inactiveSubscribers = 0;
  int totalAdmins = 0;

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredActiveSubscribers = [];
  List<Map<String, dynamic>> filteredInactiveSubscribers = [];
  List<Map<String, dynamic>> filteredAdmins = [];

  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter users based on role and subscription status
  void _filterUsers() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredAdmins = users.where((user) {
        final email = user['email']?.toLowerCase() ?? '';
        return user['role'] == 'admin' && email.contains(query);
      }).toList();

      filteredActiveSubscribers = users.where((user) {
        final subscriptionEnd = user['subscriptionEnd']?.toDate();
        final email = user['email']?.toLowerCase() ?? '';
        return subscriptionEnd != null &&
            subscriptionEnd.isAfter(DateTime.now()) &&
            email.contains(query) &&
            user['role'] != 'admin';
      }).toList();

      filteredInactiveSubscribers = users.where((user) {
        final subscriptionEnd = user['subscriptionEnd']?.toDate();
        final email = user['email']?.toLowerCase() ?? '';
        return (subscriptionEnd == null || subscriptionEnd.isBefore(DateTime.now())) &&
            email.contains(query) &&
            user['role'] != 'admin';
      }).toList();
    });
  }

  void _showUserDetails(Map<String, dynamic> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(
          userData: userData,
          userId: userData['id'], // Pass the userId to UserDetailScreen
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Area', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No users found.'));
          }

          // Update user data dynamically
          users = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id; // Include the userId (document ID)
            return data;
          }).toList();

          // Update user counts
          totalUsers = users.length;
          filteredAdmins = users.where((user) => user['role'] == 'admin').toList();
          filteredActiveSubscribers = users.where((user) {
            final subscriptionEnd = user['subscriptionEnd']?.toDate();
            return subscriptionEnd != null &&
                subscriptionEnd.isAfter(DateTime.now()) &&
                user['role'] != 'admin';
          }).toList();
          filteredInactiveSubscribers = users.where((user) {
            final subscriptionEnd = user['subscriptionEnd']?.toDate();
            return (subscriptionEnd == null || subscriptionEnd.isBefore(DateTime.now())) &&
                user['role'] != 'admin';
          }).toList();

          activeSubscribers = filteredActiveSubscribers.length;
          inactiveSubscribers = filteredInactiveSubscribers.length;
          totalAdmins = filteredAdmins.length;

          // Render UI
          return Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Users: $totalUsers', style: TextStyle(fontSize: 18)),
                    Row(
                      children: [
                        Icon(Icons.supervisor_account, color: Colors.blue),
                        SizedBox(width: 5),
                        Text('$totalAdmins', style: TextStyle(color: Colors.blue)),
                        SizedBox(width: 15),
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 5),
                        Text('$activeSubscribers', style: TextStyle(color: Colors.green)),
                        SizedBox(width: 15),
                        Icon(Icons.cancel, color: Colors.red),
                        SizedBox(width: 5),
                        Text('$inactiveSubscribers', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ],
                ),
              ),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by email',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              // User Lists
              Expanded(
                child: ListView(
                  children: [
                    // Admins Section
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Admins',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                    ...filteredAdmins.map((user) => ListTile(
                          title: Text(user['name'] ?? 'No Name'),
                          subtitle: Text(user['email'] ?? 'No Email'),
                          onTap: () => _showUserDetails(user),
                        )),

                    // Active Subscribers Section
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Active Subscribers',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                    ...filteredActiveSubscribers.map((user) => ListTile(
                          title: Text(user['name'] ?? 'No Name'),
                          subtitle: Text(user['email'] ?? 'No Email'),
                          onTap: () => _showUserDetails(user),
                        )),

                    // Inactive Subscribers Section
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Inactive Subscribers',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ),
                    ...filteredInactiveSubscribers.map((user) => ListTile(
                          title: Text(user['name'] ?? 'No Name'),
                          subtitle: Text(user['email'] ?? 'No Email'),
                          onTap: () => _showUserDetails(user),
                        )),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
