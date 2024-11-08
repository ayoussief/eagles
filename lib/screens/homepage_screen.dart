import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eagles/constants.dart';
import 'package:eagles/screens/adminpost_screen.dart';
import 'package:eagles/screens/news_screen.dart';
import 'package:eagles/screens/profile_screen.dart';
import 'package:eagles/screens/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePageScreen extends StatefulWidget {
  static String id = 'HomePageScreen';

  @override
  _HomePageScreenState createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  // Fetch user role from Firestore
  void _fetchUserRole() async {
    try {
      // Get the current user ID from Firebase Auth
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

        if (userDoc.exists) {
          setState(() {
            _isAdmin = userDoc.data()?['role'] == 'admin';
          });
          print("User role: ${userDoc.data()?['role']}"); // Debug print
          print("Is Admin: $_isAdmin"); // Confirm if _isAdmin is set correctly
        } else {
          print("User document does not exist in Firestore.");
        }
      } else {
        print("User is not logged in.");
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
  }

  final List<Widget> _screens = [
    HomeScreen(),
    NewsScreen(),
    ProfileScreen(),
    SettingsScreen(),
    AdminPostScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Eagles', style: TextStyle(color: Colors.white)),
        backgroundColor: KMainColor,
      ),
      body: Container(
        color: KSecondaryColor,
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: KMainColor),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: KSecondaryColor,
          unselectedItemColor: Colors.white,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article),
              label: 'News',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
            if (_isAdmin) 
              BottomNavigationBarItem(
                icon: Icon(Icons.add),
                label: 'Post',
              ),
          ],
        ),
      ),
    );
  }
}




// Home screen widget
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No posts available.'));
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (ctx, index) {
            final post = posts[index];
            return Card(
              margin: EdgeInsets.all(10),
              elevation: 5,
              child: ListTile(
                title: Text(
                  post['title'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(post['content']),
                trailing: post['imageUrl'] != null
                    ? Image.network(post['imageUrl'])
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}