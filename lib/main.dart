import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:semesterproject/views/screens/about_us.dart';
import 'package:semesterproject/views/screens/owner_home_screen.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/business_detail_screen.dart';
import 'views/screens/profile_screen.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/admin_panel_screen.dart';
import 'views/screens/owner_panel_screen.dart';

String currentUserId = '';
String currentUserName = '';
String currentUserEmail = '';
bool isAdmin = false;
bool isOwner = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yelp Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/admin': (context) => AdminPanelScreen(),
        '/owner': (context) => OwnerPanelScreen(),
        '/ownerhome' : (context) => OwnerHomePage(),
        '/aboutus' : (context) => AboutUsScreen(),

      },
      onGenerateRoute: (settings) {
        if (settings.name!.startsWith('/business/')) {
          final id = settings.name!.replaceFirst('/business/', '');
          return MaterialPageRoute(
            builder: (context) => BusinessDetailScreen(businessId: id),
          );
        }
        return null;
      },
    );
  }
}