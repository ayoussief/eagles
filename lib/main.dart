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
import 'package:cloud_firestore/cloud_firestore.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Define translations for each supported language
Map<String, Map<String, String>> translations = {
  'en': {
    'settingsTitle': 'Settings',
    'saveChanges': 'Save Changes',
    'acceptTerms': 'I accept the terms and conditions',
    // Add more English strings here
  },
  'ar': {
    'settings': 'الاعدادات',
    'saveChanges': 'حفظ التغييرات',
    'acceptTerms': 'أوافق على الشروط والأحكام',
    // Add more Arabic strings here
    'home': 'الرئيسية',
    'news': 'الاخبار',
    'profile': 'الملف الشخصى',
    'name_not_available': 'الاسم غير متاح',
    'email_not_available': 'الايميل غير متاح',
    'role': 'الدور',
    'role_not_available': 'الدور غير متاح',
    'joined': 'تاريخ الانضمام',
    'total_balance': 'اجمالى الرصيد',
    'used_balance': 'الرصيد المستخدم',
    'free_balance': 'الرصيد المتاح',
    'subscription_period': 'مدة الاشتراك',
    'days_left': 'الايام المتبقية',
    'subscription_data_not_available': 'تفاصيل الاشتراك غير متوفرة',
    'your_stocks': 'الأسهم الخاصة بك',
    'unknown_stock': 'سهم غير معروف',
    'quantity': 'الكمية',
    'entry_price': 'سعر الدخول',
    'no_stocks_added': 'لم تتم إضافة أي أسهم',
    'add_stock': 'إضافة سهم',
  },
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseAuth auth = FirebaseAuth.instance;
  User? user = auth.currentUser;

  String userPreferredLanguage = 'en';
  if (user != null) {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    userPreferredLanguage = userDoc['preferredLanguage'] ?? 'en';
  }

  runApp(MyApp(
    initialRoute: user != null ? HomePageScreen.id : LoginScreen.id,
    userPreferredLanguage: userPreferredLanguage,
  ));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final String userPreferredLanguage;

  const MyApp({super.key, required this.initialRoute, required this.userPreferredLanguage});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ModalHud>(
      create: (context) => ModalHud(),
      child: MaterialApp(
        initialRoute: initialRoute,
        // Pass the selected language to the widgets
        home: HomePageScreen(languageCode: userPreferredLanguage),
        routes: {
          LoginScreen.id: (context) => LoginScreen(),
          SignupScreen.id: (context) => SignupScreen(),
          HomePageScreen.id: (context) => HomePageScreen(languageCode: userPreferredLanguage),
        },
      ),
    );
  }
}
