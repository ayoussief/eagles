import 'package:eagles/screens/login_screen.dart'; // Import your LoginScreen
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase auth

class SupportScreen extends StatelessWidget {
  static String id = 'SupportScreen';

  // Function to log out the user
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign out from Firebase
      // After logging out, navigate to the login screen
      Navigator.pushReplacementNamed(context, LoginScreen.id);
    } catch (e) {
      // Handle any errors during sign out
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subscription Expired or Invalid',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'We noticed that your subscription has expired or there is no active subscription associated with your account. To continue enjoying our services, please renew your subscription.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'If you need assistance or have any questions, please reach out to our support team:',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                // Optionally open a URL, like a WhatsApp link or email
                final Uri _url = Uri.parse('https://chat.whatsapp.com/K3GZrGnECgxA4nw7nbywgw');
                //launchUrl(_url); // You'll need to import 'url_launcher' package to use this
              },
              child: const Text(
                'WhatsApp: +201019230287 / +201278886884',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            // Log Out Button
            Center(
              child: ElevatedButton(
                onPressed: () => _logout(context), // Log out on button press
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Button color (updated)
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Log Out',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
