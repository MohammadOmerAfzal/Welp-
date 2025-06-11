import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/restaurant_detail_screen.dart';
import 'views/screens/profile_screen.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/admin_panel_screen.dart';

String currentUserId = '';
String currentUserName = '';
String currentUserEmail = '';
bool isAdmin = false;

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
      },
      onGenerateRoute: (settings) {
        if (settings.name!.startsWith('/restaurant/')) {
          final id = settings.name!.replaceFirst('/restaurant/', '');
          return MaterialPageRoute(
            builder: (context) => RestaurantDetailScreen(restaurantId: id),
          );
        }
        return null;
      },
    );
  }
}