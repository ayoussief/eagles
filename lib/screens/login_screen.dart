import 'package:eagles/constants.dart';
import 'package:eagles/providers/language_provider.dart';
import 'package:eagles/providers/modal_hud.dart';
import 'package:eagles/screens/homepage_screen.dart';
import 'package:eagles/screens/signup_screen.dart';
import 'package:eagles/screens/support_screen.dart';
import 'package:eagles/services/auth.dart';
import 'package:eagles/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

final Uri _url = Uri.parse('https://chat.whatsapp.com/K3GZrGnECgxA4nw7nbywgw');

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});
  static String id = 'LoginScreen';
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  String? _email, _password;
  final _auth = Auth();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _loadPreferredLanguage(
      BuildContext context, String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        String? preferredLanguage = userDoc['preferredLanguage'] as String?;
        if (preferredLanguage != null) {
          Provider.of<LanguageProvider>(context, listen: false)
              .setLocale(preferredLanguage);
        }
      }
    } catch (e) {
      print('Error loading preferred language: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: KMainColor,
      body: ModalProgressHUD(
        inAsyncCall: Provider.of<ModalHud>(context).isLoading,
        child: Form(
          key: _globalKey,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * .3,
                  child: const Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('images/icons/eagle.png'),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Text(
                          'Eagles Trading',
                          style:
                              TextStyle(fontFamily: 'Pacifico', fontSize: 25),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: height * .1,
              ),
              CustomTextField(
                onClick: (value) {
                  _email = value!.trim();
                },
                hint: 'Enter your email',
                icon: Icons.email,
              ),
              SizedBox(
                height: height * .015,
              ),
              CustomTextField(
                onClick: (value) {
                  _password = value!.trim();
                },
                hint: 'Enter your Password',
                icon: Icons.lock,
              ),
              SizedBox(
                height: height * .05,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 120),
                child: TextButton(
                  onPressed: () async {
                    final modalhud =
                        Provider.of<ModalHud>(context, listen: false);
                    modalhud.changeisLoading(true);

                    if (_globalKey.currentState?.validate() ?? false) {
                      _globalKey.currentState?.save();
                      try {
                        final userCredential =
                            await _auth.signIn(_email!, _password!);
                        final userId = userCredential.user?.uid;
                        if (userId != null) {
                          await _loadPreferredLanguage(context, userId);

                          // Fetch user data from Firestore
                          final userDoc = await _firestore
                              .collection('users')
                              .doc(userId)
                              .get();
                          final userData = userDoc.data();

                          if (userData != null) {
                            final String role =
                                userData['role'] ?? 'user'; // Default to 'user'
                            final Timestamp? subscriptionEnd =
                                userData['subscriptionEnd'];

                            if (role != 'admin') {
                              // Only check subscription if the user is not an admin
                              if (subscriptionEnd == null ||
                                  subscriptionEnd
                                      .toDate()
                                      .isBefore(DateTime.now())) {
                                modalhud.changeisLoading(false);
                                // Redirect to support page
                                Navigator.pushReplacementNamed(
                                    context, SupportScreen.id);
                                return;
                              }
                            }
                          }

                          modalhud.changeisLoading(false);

                          // Show a SnackBar message indicating successful login
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Login successful!'),
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // Navigate to the next screen
                          Navigator.pushReplacementNamed(
                              context, HomePageScreen.id);
                        }
                      } catch (e) {
                        modalhud.changeisLoading(false);
                        // Handle any errors
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'), // Show error message
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                    modalhud.changeisLoading(false);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: height * .05,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Don\'t have an account? ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, SignupScreen.id);
                    },
                    child: const Text(
                      'SignUp',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
