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
  final formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  String rating = 'Good';
  List<String> imagePaths = [];
  Position? currentPosition;
  bool isLoadingLoc = false;

  // Rating color helper
  Color colorRating(String rating) {
    switch (rating) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.blue;
      case 'Fair':
        return Colors.orange;
      case 'Poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.inspection != null) {
      nameController.text = widget.inspection!.propertyName;
      descriptionController.text = widget.inspection!.description;
      rating = widget.inspection!.rating;
      if (widget.inspection!.photos.isNotEmpty) {
        imagePaths = widget.inspection!.photos.split(',');
      }
      // Pre-load existing location if available
      if (widget.inspection!.latitude != 0.0) {
        // We create a dummy Position object for UI display purposes based on saved data
        currentPosition = Position(
          longitude: widget.inspection!.longitude,
          latitude: widget.inspection!.latitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    }
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
          style:  TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              //Property Info
              Text(
                "PROPERTY DETAILS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: nameController,
                decoration: inputDecoration(
                  "Property Name / Address",
                  Icons.home_work_outlined,
                ),
                validator: (val) =>
                    val!.isEmpty ? "Property name is required" : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: descriptionController,
                decoration: inputDecoration("Description / Issues", Icons.notes),
                maxLines: 3,
                validator: (val) =>
                    val!.isEmpty ? "Description is required" : null,
              ),
              SizedBox(height: 16),
              Text(
                "ASSESSMENT",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: rating,
                    isExpanded: true,
                    icon:  Icon(
                      Icons.arrow_drop_down_circle,
                      color: Colors.blueAccent,
                    ),
                    items: ['Excellent', 'Good', 'Fair', 'Poor'].map((label) {
                      return DropdownMenuItem(
                        value: label,
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              color: colorRating(label),
                              size: 14,
                            ),
                             SizedBox(width: 10),
                            Text(
                              label,
                              style:  TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => rating = val!),
                  ),
                ),
              ),

              SizedBox(height: 24),

              //Location
              Text(
                "LOCATION",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
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
                      padding:  EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        currentPosition != null
                            ? Icons.location_on
                            : Icons.location_off,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentPosition != null
                                ? "Location Locked"
                                : "No Location Data",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            currentPosition != null
                                ? "${currentPosition!.latitude.toStringAsFixed(5)}, ${currentPosition!.longitude.toStringAsFixed(5)}"
                                : "Tap button to fetch GPS",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: getLocation,
                      icon: isLoadingLoc
                          ?  SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          :  Icon(
                              Icons.my_location,
                              color: Colors.blueAccent,
                            ),
                      tooltip: "Get GPS",
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "EVIDENCE PHOTOS",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    "${imagePaths.length} / 3 required",
                    style: TextStyle(
                      fontSize: 12,
                      color: imagePaths.length >= 3
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
               SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: imagePaths.length + 1, // +1 for the Add button
                  separatorBuilder: (ctx, i) =>  SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == imagePaths.length) {
                      return GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blueAccent,
                              style: BorderStyle.solid,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, color: Colors.blueAccent),
                              SizedBox(height: 4),
                              Text(
                                "Add Photo",
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                ),
                              ),
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
                            File(imagePaths[index]),
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => removeImage(index),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              SizedBox(height: 40),

              // Save Button
              ElevatedButton(
                onPressed: saveRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  "SAVE INSPECTION",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
    
  }

   //Camera
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        imagePaths.add(photo.path);
      });
    }
  }

  void removeImage(int index) {
    setState(() {
      imagePaths.removeAt(index);
    });
  }

  //GPS Logic
  Future<void> getLocation() async {
    setState(() => isLoadingLoc = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => isLoadingLoc = false);
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentPosition = position;
      isLoadingLoc = false;
    });
  }

  void saveRecord() async {
    if (formKey.currentState!.validate()) {
      if (imagePaths.length < 3 && widget.inspection == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Text("Requirement: Please take at least 3 photos..."),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      double lat = currentPosition?.latitude ?? 0.0;
      double lng = currentPosition?.longitude ?? 0.0;

      Inspection newInspection = Inspection(
        id: widget.inspection?.id,
        propertyName: nameController.text,
        description: descriptionController.text,
        rating: rating,
        latitude: lat,
        longitude: lng,
        dateCreated:
            widget.inspection?.dateCreated ?? DateTime.now().toString(),
        photos: imagePaths.join(','),
      );

      if (widget.inspection == null) {
        await DatabaseHelper.instance.create(newInspection);
      } else {
        await DatabaseHelper.instance.update(newInspection);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  InputDecoration inputDecoration(String label, IconData icon) {
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
        borderSide:  BorderSide(color: Colors.blueAccent, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
