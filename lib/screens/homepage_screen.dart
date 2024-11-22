import 'package:eagles/main.dart';
import 'package:eagles/screens/login_screen.dart';
import 'package:eagles/screens/support_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eagles/constants.dart';
import 'package:eagles/screens/adminarea_screen.dart';
import 'package:eagles/screens/adminpost_screen.dart';
import 'package:eagles/screens/home_screen.dart';
import 'package:eagles/screens/news_screen.dart';
import 'package:eagles/screens/profile_screen.dart';
import 'package:eagles/screens/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePageScreen extends StatefulWidget {
  static String id = 'HomePageScreen';
  final String languageCode;

  const HomePageScreen({super.key, required this.languageCode});

  @override
  _HomePageScreenState createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  late final Stream<DocumentSnapshot> _userSubscriptionStream;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();

    // Set up real-time listener for subscription status
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _userSubscriptionStream = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots();
    }
  }

  // Fetch user role from Firestore
  void _fetchUserRole() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          setState(() {
            _isAdmin = userDoc.data()?['role'] == 'admin';
          });
          print("User role: ${userDoc.data()?['role']}");
          print("Is Admin: $_isAdmin");
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

  List<Widget> get _screens {
    List<Widget> screens = [
      HomeScreen(),
      NewsScreen(),
      ProfileScreen(languageCode: widget.languageCode),
      SettingsScreen(),
    ];
    if (_isAdmin) {
      screens.add(AdminPostScreen());
    }
    return screens;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userSubscriptionStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Error'),
            ),
            body: Center(child: Text("An error occurred.")),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final subscriptionEnd = userData['subscriptionEnd']?.toDate();
          final userRole = userData['role'];

          // Check subscription only for non-admin users
          if (userRole != 'admin') {
            if (subscriptionEnd != null &&
                subscriptionEnd.isBefore(DateTime.now())) {
              // Redirect to SupportScreen
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(context, SupportScreen.id);
              });
            }
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Eagles', style: TextStyle(color: Colors.white)),
            backgroundColor: KMainColor,
            actions: [
              if (_isAdmin) // Only display the admin icon if the user is an admin
                IconButton(
                  icon: Icon(Icons.admin_panel_settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminAreaScreen(),
                      ),
                    );
                  },
                ),
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, LoginScreen.id);
                },
              ),
            ],
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
              unselectedItemColor: Colors.black,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: translations[widget.languageCode]?['home'] ?? 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.article),
                  label: translations[widget.languageCode]?['news'] ?? 'News',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: translations[widget.languageCode]?['profile'] ??
                      'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: translations[widget.languageCode]?['settings'] ??
                      'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}