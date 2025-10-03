import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:local_auth/local_auth.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();
  bool isLoading = false;
  bool _obscurePin = true;
  bool _biometricAvailable = false;

  // Default PIN for demo purposes - in real app, this should be configurable
  static const String defaultPin = "1234";

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final bool isAvailable = await auth.isDeviceSupported();
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      setState(() {
        _biometricAvailable = isAvailable && canCheckBiometrics;
      });
    } catch (e) {
      print('Error checking biometric availability: $e');
    }
  }

  Future<void> authenticateWithBiometrics() async {
    setState(() => isLoading = true);
    
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access your expense tracker',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        await _performLogin();
      } else {
        Fluttertoast.showToast(msg: 'Biometric authentication failed');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Biometric error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> authenticateWithPin() async {
    if (_pinController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter your PIN');
      return;
    }

    setState(() => isLoading = true);
    
    try {
      // Get stored PIN from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? storedPin = prefs.getString('user_pin');
      
      // If no PIN is stored, use default PIN
      storedPin ??= defaultPin;

      if (_pinController.text == storedPin) {
        await _performLogin();
      } else {
        Fluttertoast.showToast(msg: 'Incorrect PIN. Please try again.');
        _pinController.clear();
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _performLogin() async {
    try {
      // Save login session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', 'Kiran');
      await prefs.setDouble('monthlyBudget', 15000);
      await prefs.setInt('loggingStreak', 7);
      
      // Initialize account balance if not set
      final currentBalance = prefs.getDouble('accountBalance');
      if (currentBalance == null) {
        await prefs.setDouble('accountBalance', 50000.0); // Default balance
      }

      Fluttertoast.showToast(msg: "Login successful!");
      
      // Navigate to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Login error: $e');
    }
  }

  Future<void> _showChangePinDialog() async {
    final TextEditingController newPinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set New PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                hintText: 'Enter 4-6 digit PIN',
              ),
            ),
            TextField(
              controller: confirmPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                hintText: 'Re-enter PIN',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPinController.text.length < 4) {
                Fluttertoast.showToast(msg: 'PIN must be at least 4 digits');
                return;
              }
              if (newPinController.text != confirmPinController.text) {
                Fluttertoast.showToast(msg: 'PINs do not match');
                return;
              }
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_pin', newPinController.text);
              Fluttertoast.showToast(msg: 'PIN set successfully');
              Navigator.pop(context);
            },
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB39DDB), Color(0xFFD1C4E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.deepPurple,
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Enter your PIN to access your expense tracker',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _pinController,
                        obscureText: _obscurePin,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          labelText: 'PIN',
                          hintText: 'Enter your 4-6 digit PIN',
                          counterText: '',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePin ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePin = !_obscurePin;
                              });
                            },
                          ),
                        ),
                        onSubmitted: (_) => authenticateWithPin(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.lock_open, color: Colors.white),
                        onPressed: isLoading ? null : authenticateWithPin,
                        label: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Login with PIN',
                                style: TextStyle(color: Colors.white),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    // Fingerprint option
                    if (_biometricAvailable) ...[
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR', style: TextStyle(color: Colors.grey)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.fingerprint, color: Colors.deepPurple),
                          onPressed: isLoading ? null : authenticateWithBiometrics,
                          label: const Text(
                            'Login with Fingerprint',
                            style: TextStyle(color: Colors.deepPurple),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.deepPurple),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _showChangePinDialog,
                      child: const Text("Change PIN"),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Default PIN: 1234',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Remove the parseJwt function as it's no longer needed