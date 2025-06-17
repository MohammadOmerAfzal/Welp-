import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:semesterproject/views/widgets/business_card_reviews.dart';
import '../../controllers/business_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/business_model.dart';
import '../../models/user_model.dart' as myuser;

class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({Key? key}) : super(key: key);

  @override
  _OwnerHomePageState createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage> {
  final BusinessController _businessController = BusinessController();
  final UserController _userController = UserController();

  List<Business> _businesses = [];
  myuser.User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndBusinesses();
  }

  Future<void> _loadUserAndBusinesses() async {
    final fb_auth.User? firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      final myuser.User? fetchedUser = await _userController.getUser(firebaseUser.uid);
      setState(() {
        _currentUser = fetchedUser;
      });

      final businesses = await _businessController.fetchBusinessesByUser(firebaseUser.uid);
      setState(() {
        _businesses = businesses;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await fb_auth.FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/home');
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.verified_user),
                title: const Text('About Us'),
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/aboutus', (_) => false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text("Welcome, ${fb_auth.FirebaseAuth.instance.currentUser?.displayName ?? 'Owner'}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _businesses.isEmpty
            ? const Center(child: Text("No businesses registered yet."))
            : ListView.builder(
          itemCount: _businesses.length,
          itemBuilder: (context, index) {
            return BusinessCardReviews(business: _businesses[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/owner').then((_) => _loadUserAndBusinesses());
        },
        icon: const Icon(Icons.add_business),
        label: const Text('Add Business'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
