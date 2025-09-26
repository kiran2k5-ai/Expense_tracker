import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'main_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final userNameController = TextEditingController();
  final monthlyBudgetController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;

  Future<void> registerUser() async {
    setState(() => isLoading = true);

    final url = Uri.parse('http://localhost:5000/api/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
          'userName': userNameController.text,
          'monthlyBudget': double.tryParse(monthlyBudgetController.text) ?? 0.0,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['token'] != null) {
        final token = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        final decoded = parseJwt(token);
        final userId = decoded['userId'];

        Fluttertoast.showToast(msg: "Registered successfully!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainScaffold(userId: userId),
          ),
        );
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Create an Account",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(emailController, "Email", Icons.email),
                  const SizedBox(height: 16),
                  _buildTextField(userNameController, "Full Name", Icons.person),
                  const SizedBox(height: 16),
                  _buildTextField(monthlyBudgetController, "Monthly Budget", Icons.account_balance_wallet,
                      inputType: TextInputType.number),
                  const SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (context, setStateSB) {
                      return TextField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setStateSB(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildRegisterButton(),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? inputType}) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Icon(Icons.app_registration, color: Colors.white),
        label: Text(
          isLoading ? '' : 'Register',
          style: const TextStyle(color: Colors.white),
        ),
        onPressed: isLoading ? null : registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

Map<String, dynamic> parseJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) throw Exception('Invalid token');

  final payload = base64Url.normalize(parts[1]);
  final payloadMap = json.decode(utf8.decode(base64Url.decode(payload)));

  if (payloadMap is! Map<String, dynamic>) {
    throw Exception('Invalid payload');
  }

  return payloadMap;
}
