import 'package:eagles/constants.dart';
import 'package:eagles/providers/modal_hud.dart';
import 'package:eagles/screens/login_screen.dart';
import 'package:eagles/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:eagles/services/auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatelessWidget {
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  static String id = "SignupScreen";
  String? _name , _email, _password;
  final _auth = Auth();

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
                          style: TextStyle(fontFamily: 'Pacifico', fontSize: 25),
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
                    _name = value!.trim();
                  },
                  icon: Icons.person,
                  hint: "Enter your name"),
              SizedBox(
                height: height * .015,
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
                  // onPressed: () async {
                  //   if (_globalKey.currentState?.validate() ?? false) {
                  //     _globalKey.currentState?.save();
                  //     print(_email);
                  //     print(_password);
                  //     try {
                  //       final userCredential = await _auth.signUp(_email!, _password!);
                  //       print(userCredential.user!.uid);
                  //       // Navigate to another screen upon successful signup
                  //     } catch (e) {
                  //       // Handle any errors
                  //       print('Error: $e'); // Show a dialog or snackbar with the error message.
                  //     }
                  //   }
                  // },
        
                  onPressed: () async {
                    final modalhud = Provider.of<ModalHud>(context, listen: false);
                    modalhud.changeisLoading(true);

                    if (_globalKey.currentState?.validate() ?? false) {
                      _globalKey.currentState?.save();
                      try {
                            final userCredential =
                                await _auth.signUp(_name!, _email!, _password!);

                                modalhud.changeisLoading(false);
                                // Show a SnackBar message indicating successful signup
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Signup successful!'),
                                    duration: Duration(
                                        seconds:
                                            2), // Duration the SnackBar will be visible
                                  ),
                                );
            
                            // Navigate to the LoginScreen after successful signup
                            Navigator.pushReplacementNamed(context, LoginScreen.id);
                          } catch (e) {
                                modalhud.changeisLoading(false);
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
                      borderRadius: BorderRadius.circular(
                          20), // Set your desired border radius
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: height * .05,
              ),
              // const Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Text(
              //       'Don\'t have an account?',
              //       style: TextStyle(
              //         color: Colors.white,
              //         fontSize: 16
              //       ),
              //     ),
              //     Text(
              //       'Contact us',
              //       style: TextStyle(
              //         fontSize: 16
              //       ),
              //     ),
              //   ],
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, LoginScreen.id);
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors
                            .black, // Optional: change color for better visibility
                        decoration: TextDecoration
                            .none, // Optional: underline for link effect
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