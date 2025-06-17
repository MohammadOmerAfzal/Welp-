import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';


class OwnerPanelScreen extends StatefulWidget {
  @override
  _OwnerPanelScreenState createState() => _OwnerPanelScreenState();
}

class _OwnerPanelScreenState extends State<OwnerPanelScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final DatabaseReference _businessRef = FirebaseDatabase.instance.ref().child('businesses');
  GoogleMapController? _mapController; // add this



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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location permission denied'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition();

    setState(() {
      _selectedLocation = LatLng(pos.latitude, pos.longitude);
    });

    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(_selectedLocation!));
    }
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
        SnackBar(
          content: Text('Please fill in all fields'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
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
        SnackBar(
          content: Text('✅ Business uploaded successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Upload failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.grey[900]!, Colors.grey[850]!]
                : [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Business Registration',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.logout, color: Colors.white),
                      onPressed: _logout,
                    ),
                  ],
                ).animate().fadeIn(delay: 8.ms),

                SizedBox(height: 20),

                // Business Details Card
                _buildNeumorphicCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        icon: Icons.business,
                        title: "Business Details",
                        subtitle: "Fill in your business information",
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _nameController,
                        label: "Business Name",
                        hint: "Enter your business name",
                        icon: Icons.store,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _descriptionController,
                        label: "Description",
                        hint: "Tell customers about your business",
                        icon: Icons.description,
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      _buildDropdownField(
                        value: _selectedCategory,
                        items: _categories,
                        label: "Category",
                        hint: "Select business category",
                        icon: Icons.category,
                        onChanged: (value) => setState(() => _selectedCategory = value),
                      ),
                    ],
                  ),
                ).animate().slideX(duration: 8.ms),

                SizedBox(height: 24),

                // Images Section Card
                _buildNeumorphicCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        icon: Icons.photo_library,
                        title: "Business Images",
                        subtitle: "Upload photos of your business",
                      ),
                      SizedBox(height: 16),
                      _buildImagePickerSection(),
                    ],
                  ),
                ).animate().slideX(delay: 8.ms),

                SizedBox(height: 24),

                // Location Section Card
                _buildNeumorphicCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        icon: Icons.location_on,
                        title: "Business Location",
                        subtitle: "Set your business location on the map",
                      ),
                      SizedBox(height: 16),
                      _buildLocationSection(),
                    ],
                  ),
                ).animate().slideX(delay: 8.ms),

                SizedBox(height: 30),

                // Submit Button
                _buildSubmitButton().animate().fadeIn(delay: 8.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicCard({required Widget child}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black54 : Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[700]
            : Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required String label,
    required String hint,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[700]
            : Colors.grey[50],
      ),
      borderRadius: BorderRadius.circular(12),
      dropdownColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.white,
      icon: Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
    );
  }

  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_pickedImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _pickedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _pickedImages[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _pickedImages.removeAt(index);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        else
          Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1.5, style: BorderStyle.none),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 40, color: Colors.grey),
                  Text("No images selected", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),

        SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: Icon(Icons.add_photo_alternate),
          label: Text('Add Photos'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _selectedLocation ?? LatLng(37.4219999, -122.0840575),
                zoom: 14,
              ),
              onTap: _onMapTap,
              markers: _selectedLocation != null
                  ? {
                Marker(
                  markerId: MarkerId('selected'),
                  position: _selectedLocation!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                ),
              }
                  : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
        ),

        SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _getCurrentLocation,
                icon: Icon(Icons.my_location, size: 20),
                label: Text('Current Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.blueAccent),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_selectedLocation == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please select a location on the map'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                icon: Icon(Icons.map, size: 20),
                label: Text('Confirm Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        if (_selectedLocation != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'Location selected',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isUploading ? null : _uploadBusiness,
      child: _isUploading
          ? Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          SizedBox(width: 12),
          Text('Uploading...'),
        ],
      )
          : Text(
        'Register Business',
        style: TextStyle(fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
        shadowColor: Colors.blueAccent.withOpacity(0.4),
      ),
    );
  }
}