import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  double _monthlyBudget = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      Fluttertoast.showToast(msg: "No token found. Please log in.");
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final url = Uri.parse('http://localhost:5000/api/auth/profile');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _userName = data['userName'] ?? 'User';
          _monthlyBudget = (data['monthlyBudget'] ?? 15000).toDouble();
        });

        prefs.setString('userName', _userName);
        prefs.setDouble('monthlyBudget', _monthlyBudget);
      } else {
        Fluttertoast.showToast(msg: 'Failed to load profile');
        print('Failed to load profile: ${response.body}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading profile');
      print('Error loading profile: $e');
    }
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _userName);
    final budgetController =
        TextEditingController(text: _monthlyBudget.toString());

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      Fluttertoast.showToast(msg: "No token found. Please log in.");
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Edit Profile',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 10),
              TextField(
                  controller: budgetController,
                  decoration:
                      const InputDecoration(labelText: 'Monthly Budget'),
                  keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save'),
              onPressed: () async {
                final newName = nameController.text;
                final newBudget =
                    double.tryParse(budgetController.text) ?? 15000;

                final url = Uri.parse(
                    'http://localhost:5000/api/auth/${widget.userId}/update');
                try {
                  final res = await http.put(
                    url,
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $token',
                    },
                    body: json.encode({
                      'userName': newName,
                      'monthlyBudget': newBudget,
                    }),
                  );

                  if (res.statusCode == 200) {
                    final prefs = await SharedPreferences.getInstance();
                    prefs.setString('userName', newName);
                    prefs.setDouble('monthlyBudget', newBudget);

                    setState(() {
                      _userName = newName;
                      _monthlyBudget = newBudget;
                    });
                    Fluttertoast.showToast(
                        msg: "Profile updated successfully!");
                    Navigator.pop(context);
                  } else {
                    Fluttertoast.showToast(
                        msg: 'Failed to update profile: ${res.body}');
                    Navigator.pop(context);
                  }
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Error updating profile');
                  Navigator.pop(context);
                }
              },
            )
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _navigateToReport() {
    Navigator.pushNamed(context, 'monthly-report');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 2,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Prominent Profile Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.account_circle,
                          size: 100,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.deepPurple.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            "Monthly Budget: ₹${_monthlyBudget.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons Section
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToReport,
                    icon: const Icon(Icons.assessment, color: Colors.white),
                    label: const Text(
                      'View Monthly Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
