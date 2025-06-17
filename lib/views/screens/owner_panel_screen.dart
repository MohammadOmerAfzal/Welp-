// ------------------ views/screens/owner_panel_screen.dart ------------------``
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class OwnerPanelScreen extends StatefulWidget {
  @override
  _OwnerPanelScreenState createState() => _OwnerPanelScreenState();
}

class _OwnerPanelScreenState extends State<OwnerPanelScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final DatabaseReference _businessRef = FirebaseDatabase.instance.ref().child('businesses');

  List<File> _pickedImages = [];
  LatLng? _selectedLocation;
  String? _selectedCategory;
  bool _isUploading = false;

  final List<String> _categories = ['Restaurant', 'Salon', 'Gym', 'Store', 'Other'];

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _pickedImages = picked.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission denied')),
      );
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _selectedLocation = LatLng(pos.latitude, pos.longitude);
    });
  }

  void _onMapTap(LatLng pos) {
    setState(() {
      _selectedLocation = pos;
    });
  }

  Future<void> _uploadBusiness() async {
    if (_nameController.text.isEmpty || _descriptionController.text.isEmpty ||
        _selectedLocation == null || _pickedImages.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isUploading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final encodedImages = await Future.wait(_pickedImages.map((file) async {
        final bytes = await file.readAsBytes();
        return base64Encode(bytes);
      }));

      final newRef = _businessRef.push();
      await newRef.set({
        'ownerId': user.uid,
        'name': _nameController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'images': encodedImages,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
      });

      _nameController.clear();
      _descriptionController.clear();
      setState(() {
        _pickedImages.clear();
        _selectedLocation = null;
        _selectedCategory = null;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Business uploaded successfully')),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Owner Panel'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Business Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
              decoration: InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 10),
            _pickedImages.isNotEmpty
                ? SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _pickedImages.map((img) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Image.file(img, height: 100, width: 100, fit: BoxFit.cover),
                )).toList(),
              ),
            )
                : Text("No images selected"),
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: Icon(Icons.image),
              label: Text('Pick Images'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: Icon(Icons.my_location),
              label: Text('Use Current Location'),
            ),
            SizedBox(
              height: 200,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(37.4219999, -122.0840575),
                  zoom: 14,
                ),
                onTap: _onMapTap,
                markers: _selectedLocation != null
                    ? {
                  Marker(
                    markerId: MarkerId('selected'),
                    position: _selectedLocation!,
                  ),
                }
                    : {},
              ),
            ),
            const SizedBox(height: 20),
            _isUploading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _uploadBusiness,
              child: Text('Register Business'),
            ),
          ],
        ),
      ),
    );
  }
}
