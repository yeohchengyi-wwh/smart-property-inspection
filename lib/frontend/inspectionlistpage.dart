import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartpropertyinspection/databasehelper.dart';
import 'package:smartpropertyinspection/model/inspection.dart';
import 'package:smartpropertyinspection/frontend/addinspectionpage.dart';
import 'package:smartpropertyinspection/frontend/detailinspectionpage.dart';
import 'package:smartpropertyinspection/frontend/loginpage.dart';

class InspectionListScreen extends StatefulWidget {
  const InspectionListScreen({super.key});

  @override
  State<InspectionListScreen> createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends State<InspectionListScreen> {
  late Future<List<Inspection>> _inspectionList;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  // Helper to format date
  String formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('MMM d, y • h:mm a').format(date);
    } catch (e) {
      return dateString; // Fallback if parsing fails
    }
  }

  // Helper to get color based on rating
  Color getcolorRating(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 2.5) return Colors.orange;
    return Colors.red;
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
          "My Inspections",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: logout,
            icon: Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddInspectionScreen(),
            ),
          );
          refresh();
        },
        backgroundColor: Colors.blueAccent,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text("New Inspection", style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<Inspection>>(
        future: _inspectionList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Inspection item = snapshot.data![index];
              return _buildInspectionCard(item);
            },
          );
        },
      ),
    );
  }

  void refresh() {
    setState(() {
      _inspectionList = DatabaseHelper.instance.readAllInspections();
    });
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            "No inspections yet",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Tap the + button to add one.",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionCard(Inspection item) {
    double ratingVal = double.tryParse(item.rating.toString()) ?? 0.0;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InspectionDetailScreen(inspection: item),
          ),
        );
        refresh();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            //Icon and Property Name
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.home_work_rounded,
                      color: Colors.blueAccent,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.propertyName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            SizedBox(width: 4),
                            Text(
                              formatDate(item.dateCreated),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(height: 1, color: Colors.grey[200]),

            //Rating and Action
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getcolorRating(ratingVal),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: getcolorRating(ratingVal),
                            ),
                            SizedBox(width: 4),
                            Text(
                              "$ratingVal / 5",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: getcolorRating(ratingVal),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
