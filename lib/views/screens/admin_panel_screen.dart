import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final DatabaseReference _businessesRef = FirebaseDatabase.instance.ref().child('businesses');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  Future<void> _updateUserRole(String uid, {required bool isAdmin, required bool isOwner}) async {
    try {
      await _usersRef.child(uid).update({
        'isAdmin': isAdmin,
        'isOwner': isOwner,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ User role updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to update role: $e')),
      );
    }
  }

  Future<void> _deleteBusiness(String businessId) async {
    try {
      await _businessesRef.child(businessId).remove();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🗑️ Business deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to delete business: $e')),
      );
    }
  }

  Widget _buildBusinessTile(String id, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unnamed';
    final lat = data['latitude'];
    final lng = data['longitude'];
    final imageList = data['images'] as List<dynamic>?;

    Widget imageWidget = Icon(Icons.image_not_supported, color: Colors.grey);
    if (imageList != null && imageList.isNotEmpty) {
      final imageUrl = imageList.first.toString();
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: 60,
              height: 60,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      color: Colors.white,
      shadowColor: Colors.deepPurpleAccent.withOpacity(0.3),
      child: ListTile(
        leading: imageWidget,
        title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Text(
          (lat != null && lng != null)
              ? 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}'
              : 'Location: Not available',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          tooltip: 'Delete Business',
          onPressed: () => _deleteBusiness(id),
        ),
      ),
    );
  }

  Widget _buildUserTile(String uid, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? 'No email';
    final isAdmin = data['isAdmin'] == true;
    final isOwner = data['isOwner'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      color: Colors.white,
      shadowColor: Colors.deepPurple.withOpacity(0.2),
      child: ListTile(
        title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(email, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Make Admin',
              icon: Icon(Icons.admin_panel_settings, color: isAdmin ? Colors.green : Colors.grey),
              onPressed: () => _updateUserRole(uid, isAdmin: true, isOwner: false),
            ),
            IconButton(
              tooltip: 'Make Owner',
              icon: Icon(Icons.store_mall_directory, color: isOwner ? Colors.orange : Colors.grey),
              onPressed: () => _updateUserRole(uid, isAdmin: false, isOwner: true),
            ),
            IconButton(
              tooltip: 'Make Normal User',
              icon: Icon(Icons.person_off),
              onPressed: () => _updateUserRole(uid, isAdmin: false, isOwner: false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF2F3F8),
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 4,
        title: Text('Admin Panel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('📍 Businesses List', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22)),
            ),
            StreamBuilder<DatabaseEvent>(
              stream: _businessesRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return Center(child: Text('No businesses found.', style: GoogleFonts.poppins()));
                }

                final businesses = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final list = businesses.entries.toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final id = list[index].key;
                    final data = Map<String, dynamic>.from(list[index].value);
                    return _buildBusinessTile(id, data);
                  },
                );
              },
            ),
            const Divider(height: 40),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('👥 User Management', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22)),
            ),
            StreamBuilder<DatabaseEvent>(
              stream: _usersRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return Center(child: Text('No users found.', style: GoogleFonts.poppins()));
                }

                final users = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final entries = users.entries.toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final uid = entries[index].key;
                    final data = Map<String, dynamic>.from(entries[index].value);
                    return _buildUserTile(uid, data);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}