import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'userdetail_screen.dart'; // Make sure this import points to your UserDetailScreen file

class AdminAreaScreen extends StatefulWidget {
  static String id = 'AdminAreaScreen';

  @override
  _AdminAreaScreenState createState() => _AdminAreaScreenState();
}

class _AdminAreaScreenState extends State<AdminAreaScreen> {
  int totalUsers = 0;
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Fetch users from Firestore
  void _fetchUsers() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        totalUsers = querySnapshot.docs.length;
        users = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Include the userId (document ID)
          return data;
        }).toList();
      });
    } catch (e) {
      print("Error fetching users: $e");
    }
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
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Total Users: $totalUsers', style: TextStyle(fontSize: 20)),
          ),
          ...users.map((user) => ListTile(
                title: Text(user['name'] ?? 'No Name'),
                subtitle: Text(user['email'] ?? 'No Email'),
                onTap: () => _showUserDetails(user), // Call _showUserDetails on tap
              )),
        ],
      ),
    );
  }
}