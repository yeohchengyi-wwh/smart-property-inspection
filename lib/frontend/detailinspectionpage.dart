import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl dependency for date formatting
import 'package:url_launcher/url_launcher.dart';
import 'package:smartpropertyinspection/databasehelper.dart';
import 'package:smartpropertyinspection/frontend/addinspectionpage.dart';
import 'package:smartpropertyinspection/model/inspection.dart';

class InspectionDetailScreen extends StatefulWidget {
  final Inspection inspection;

  const InspectionDetailScreen({super.key, required this.inspection});

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  // Fix: Google Maps URL Scheme
  void _openMap() async {
    final double lat = widget.inspection.latitude;
    final double lng = widget.inspection.longitude;
    
    // Using the official Google Maps query parameter
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Maps')),
        );
      }
    }
  }

  // Fix: Add Confirmation Dialog for Delete
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Inspection?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await DatabaseHelper.instance.delete(widget.inspection.id!);
              if (mounted) Navigator.pop(context); // Return to list
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editRecord() {
    // We use pushReplacement so when they save the edit, it goes back to the list
    // (Or you could push and then setState to refresh details)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AddInspectionScreen(inspection: widget.inspection),
      ),
    );
  }

  // Helper for dates
  String _formatDate(String dateString) {
    try {
      return DateFormat('MMMM d, yyyy • h:mm a').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  // Helper for Rating Colors
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
  Widget build(BuildContext context) {
    List<String> photos = widget.inspection.photos.isNotEmpty 
        ? widget.inspection.photos.split(',') 
        : [];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text("Details", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent),
            onPressed: _editRecord,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _confirmDelete,
            tooltip: 'Delete',
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER SECTION ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.inspection.propertyName,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(widget.inspection.dateCreated),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRatingColor(widget.inspection.rating).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getRatingColor(widget.inspection.rating).withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 18, color: _getRatingColor(widget.inspection.rating)),
                        const SizedBox(width: 6),
                        Text(
                          widget.inspection.rating,
                          style: TextStyle(
                            color: _getRatingColor(widget.inspection.rating),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // --- DESCRIPTION SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notes, color: Colors.grey),
                          SizedBox(width: 8),
                          Text("Description / Issues", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        widget.inspection.description,
                        style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- LOCATION SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                        child: const Icon(Icons.location_on, color: Colors.blue),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Location Coordinates", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              "${widget.inspection.latitude.toStringAsFixed(5)}, ${widget.inspection.longitude.toStringAsFixed(5)}",
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openMap,
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text("Open Map"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- PHOTOS SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Evidence Photos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  photos.isEmpty
                      ? Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Center(child: Text("No photos attached")),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0, // Square images
                          ),
                          itemCount: photos.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                // Optional: Implement full screen view
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(photos[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}