import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartpropertyinspection/databasehelper.dart';
import 'package:smartpropertyinspection/model/inspection.dart';

class AddInspectionScreen extends StatefulWidget {
  final Inspection? inspection; // Null if adding new, not null if editing
  const AddInspectionScreen({super.key, this.inspection});

  @override
  State<AddInspectionScreen> createState() => _AddInspectionScreenState();
}

class _AddInspectionScreenState extends State<AddInspectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String _rating = 'Good';
  List<String> _imagePaths = [];
  Position? _currentPosition;
  bool _isLoadingLoc = false;

  // Rating color helper
  Color _getRatingColor(String rating) {
    switch (rating) {
      case 'Excellent': return Colors.green;
      case 'Good': return Colors.blue;
      case 'Fair': return Colors.orange;
      case 'Poor': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.inspection != null) {
      _nameController.text = widget.inspection!.propertyName;
      _descController.text = widget.inspection!.description;
      _rating = widget.inspection!.rating;
      if (widget.inspection!.photos.isNotEmpty) {
        _imagePaths = widget.inspection!.photos.split(',');
      }
      // Pre-load existing location if available
      if (widget.inspection!.latitude != 0.0) {
        // We create a dummy Position object for UI display purposes based on saved data
        _currentPosition = Position(
          longitude: widget.inspection!.longitude,
          latitude: widget.inspection!.latitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0, 
          altitudeAccuracy: 0, 
          headingAccuracy: 0
        );
      }
    }
  }

  // --- 1. Camera Logic ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _imagePaths.add(photo.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  // --- 2. GPS Logic ---
  Future<void> _getLocation() async {
    setState(() => _isLoadingLoc = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLoc = false);
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
      _isLoadingLoc = false;
    });
  }

  // --- 3. Save Logic ---
  void _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      if (_imagePaths.length < 3 && widget.inspection == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Requirement: Take at least 3 photos."),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      double lat = _currentPosition?.latitude ?? 0.0;
      double lng = _currentPosition?.longitude ?? 0.0;

      Inspection newInspection = Inspection(
        id: widget.inspection?.id,
        propertyName: _nameController.text,
        description: _descController.text,
        rating: _rating,
        latitude: lat,
        longitude: lng,
        dateCreated: widget.inspection?.dateCreated ?? DateTime.now().toString(),
        photos: _imagePaths.join(','),
      );

      if (widget.inspection == null) {
        await DatabaseHelper.instance.create(newInspection);
      } else {
        await DatabaseHelper.instance.update(newInspection);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  // --- UI Components ---

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          widget.inspection == null ? "New Inspection" : "Edit Inspection",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1: Property Info
              const Text("PROPERTY DETAILS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecor("Property Name / Address", Icons.home_work_outlined),
                validator: (val) => val!.isEmpty ? "Property name is required" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                decoration: _inputDecor("Description / Issues", Icons.notes),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? "Description is required" : null,
              ),
              const SizedBox(height: 16),

              // Section 2: Assessment
              const Text("ASSESSMENT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _rating,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.blueAccent),
                    items: ['Excellent', 'Good', 'Fair', 'Poor'].map((label) {
                      return DropdownMenuItem(
                        value: label,
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: _getRatingColor(label), size: 14),
                            const SizedBox(width: 10),
                            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _rating = val!),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section 3: Location
              const Text("LOCATION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _currentPosition != null ? Icons.location_on : Icons.location_off,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentPosition != null ? "Location Locked" : "No Location Data",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _currentPosition != null
                                ? "${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}"
                                : "Tap button to fetch GPS",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _getLocation,
                      icon: _isLoadingLoc
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location, color: Colors.blueAccent),
                      tooltip: "Get GPS",
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 4: Photos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("EVIDENCE PHOTOS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(
                    "${_imagePaths.length} / 3 required",
                    style: TextStyle(
                      fontSize: 12,
                      color: _imagePaths.length >= 3 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths.length + 1, // +1 for the Add button
                  separatorBuilder: (ctx, i) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    // The last item is the "Add Photo" button
                    if (index == _imagePaths.length) {
                      return GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blueAccent, style: BorderStyle.solid, width: 1),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, color: Colors.blueAccent),
                              SizedBox(height: 4),
                              Text("Add Photo", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }

                    // Display Image with Delete Button
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_imagePaths[index]),
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 40),

              // Save Button
              ElevatedButton(
                onPressed: _saveRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: const Text(
                  "SAVE INSPECTION",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}