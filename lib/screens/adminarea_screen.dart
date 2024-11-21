import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'userdetail_screen.dart'; // Ensure this points to your UserDetailScreen file

class AdminAreaScreen extends StatefulWidget {
  static String id = 'AdminAreaScreen';

  @override
  _AdminAreaScreenState createState() => _AdminAreaScreenState();
}

class _AdminAreaScreenState extends State<AdminAreaScreen> {
  TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Widget _buildUserList(
      AsyncSnapshot<QuerySnapshot> snapshot, String roleFilter, bool isActive) {
    final now = DateTime.now();

    final filteredUsers = snapshot.data!.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final role = data['role'] ?? '';
      final email = data['email']?.toLowerCase() ?? '';
      final subscriptionEnd = data['subscriptionEnd']?.toDate();

      // Role filter
      final isRoleMatched = role == roleFilter;

      // For admins, we don't check subscription status
      if (roleFilter == 'admin') {
        return isRoleMatched && email.contains(searchQuery);
      }

      // Subscription status filter for non-admin users
      final isSubscriptionMatched = isActive
          ? subscriptionEnd != null && subscriptionEnd.isAfter(now)
          : subscriptionEnd == null || subscriptionEnd.isBefore(now);

      // Search query filter
      final isSearchMatched = email.contains(searchQuery);

      return isRoleMatched && isSubscriptionMatched && isSearchMatched;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filteredUsers.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ListTile(
          title: Text(data['name'] ?? 'No Name'),
          subtitle: Text(data['email'] ?? 'No Email'),
          onTap: () => _showUserDetails({
            ...data,
            'id': doc.id, // Include document ID for user details
          }),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Area', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by email',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error fetching users: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No users found.'));
                }

                final allUsers = snapshot.data!.docs;
                final totalUsers = allUsers.length;
                final totalAdmins = allUsers
                    .where((doc) =>
                        (doc.data() as Map<String, dynamic>)['role'] == 'admin')
                    .length;
                final activeSubscribers = allUsers.where((doc) {
                  final subscriptionEnd =
                      (doc.data() as Map<String, dynamic>)['subscriptionEnd']
                          ?.toDate();
                  return subscriptionEnd != null &&
                      subscriptionEnd.isAfter(DateTime.now()) &&
                      (doc.data() as Map<String, dynamic>)['role'] != 'admin';
                }).length;
                final inactiveSubscribers =
                    totalUsers - totalAdmins - activeSubscribers;

                return ListView(
                  children: [
                    // Header Info
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Users: $totalUsers',
                              style: TextStyle(fontSize: 18)),
                          Row(
                            children: [
                              Icon(Icons.supervisor_account,
                                  color: Colors.blue),
                              SizedBox(width: 5),
                              Text('$totalAdmins',
                                  style: TextStyle(color: Colors.blue)),
                              SizedBox(width: 15),
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 5),
                              Text('$activeSubscribers',
                                  style: TextStyle(color: Colors.green)),
                              SizedBox(width: 15),
                              Icon(Icons.cancel, color: Colors.red),
                              SizedBox(width: 5),
                              Text('$inactiveSubscribers',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Admins Section
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Admins',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                    ),
                    _buildUserList(snapshot, 'admin', true),
                    // Active Subscribers Section
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Active Subscribers',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                    ),
                    _buildUserList(snapshot, 'user', true),
                    // Inactive Subscribers Section
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Inactive Subscribers',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red),
                      ),
                    ),
                    _buildUserList(snapshot, 'user', false),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
