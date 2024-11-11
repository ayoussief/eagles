import 'package:eagles/providers/modal_hud.dart';
import 'package:eagles/screens/homepage_screen.dart';
import 'package:eagles/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:eagles/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Check for existing user session using Firebase Authentication
  FirebaseAuth auth = FirebaseAuth.instance;
  User? user = auth.currentUser;

  // If the user is logged in, direct to the homepage, else to login screen
  runApp(MyApp(initialRoute: user != null ? HomePageScreen.id : LoginScreen.id));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ModalHud>(
      create: (context) => ModalHud(),
      child: MaterialApp(
        initialRoute: initialRoute,
        routes: {
          LoginScreen.id: (context) => LoginScreen(),
          SignupScreen.id: (context) => SignupScreen(),
          HomePageScreen.id: (context) => HomePageScreen(),
        },
      ),
    );
  }
}