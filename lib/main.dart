import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

// Your existing screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/monthly_report_screen.dart';
import 'screens/history_screen.dart';

final Telephony telephony = Telephony.instance;
final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local notifications only on mobile platforms
  if (!kIsWeb) {
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: initSettingsAndroid);

    await notifications.initialize(initSettings);
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String lastTransaction = "";
  Timer? monthlyNotificationTimer;

  @override
  void initState() {
    super.initState();
    // Only initialize SMS functionality on mobile platforms
    if (!kIsWeb) {
      _requestPermissions();
      _listenSms();
    }
    _setupMonthlyNotifications();
  }

  @override
  void dispose() {
    monthlyNotificationTimer?.cancel();
    super.dispose();
  }

  void _setupMonthlyNotifications() {
    // Check if it's the first day of the month
    _checkAndSendMonthlyNotification();
    
    // Set up timer to check daily at midnight
    Timer.periodic(const Duration(hours: 24), (timer) {
      _checkAndSendMonthlyNotification();
    });
  }

  Future<void> _checkAndSendMonthlyNotification() async {
    final now = DateTime.now();
    if (now.day == 1) {
      // It's the first day of the month
      final prefs = await SharedPreferences.getInstance();
      final lastNotificationMonth = prefs.getString('lastBalanceNotification');
      final currentMonth = '${now.year}-${now.month}';
      
      if (lastNotificationMonth != currentMonth) {
        // Haven't sent notification for this month yet
        final accountBalance = prefs.getDouble('accountBalance') ?? 50000.0;
        await _showMonthlyBalanceNotification(accountBalance);
        await prefs.setString('lastBalanceNotification', currentMonth);
      }
    }
  }

  Future<void> _showMonthlyBalanceNotification(double balance) async {
    if (!kIsWeb) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'monthly_balance_channel',
        'Monthly Balance',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      await notifications.show(
        1,
        'Monthly Balance Report',
        'Your current account balance: ₹${balance.toStringAsFixed(2)}',
        platformDetails,
      );
    }
  }

  void _requestPermissions() async {
    if (!kIsWeb) {
      bool? granted = await telephony.requestPhoneAndSmsPermissions;
      if (granted == false) {
        print("⚠️ SMS Permission not granted");
      }
    }
  }

  void _listenSms() {
    if (!kIsWeb) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          final body = message.body ?? "";
          print("📱 SMS Received: $body"); // Debug log

          if (_isTransactionSMS(body)) {
            _processTransactionSMS(body);
          }
        },
        listenInBackground: false,
      );
    }
  }

  bool _isTransactionSMS(String body) {
    final lowerBody = body.toLowerCase();
    
    // Check for City Union Bank (CUB) specific patterns
    if (lowerBody.contains("cub") || lowerBody.contains("city union") || lowerBody.contains("cityunion")) {
      return lowerBody.contains("debited") || lowerBody.contains("credited") ||
             lowerBody.contains("a/c") || lowerBody.contains("account");
    }
    
    // Check for transaction keywords
    return lowerBody.contains("credited") || 
           lowerBody.contains("debited") || 
           lowerBody.contains("paid") ||
           lowerBody.contains("received") ||
           lowerBody.contains("withdrawn") ||
           lowerBody.contains("spent") ||
           lowerBody.contains("upi") ||
           lowerBody.contains("transaction");
  }

  void _processTransactionSMS(String body) async {
    try {
      final lowerBody = body.toLowerCase();
      
      // Determine transaction type
      String type = "Debited";
      if (lowerBody.contains("credited") || lowerBody.contains("received")) {
        type = "Credited";
      }
      
      // Extract amount
      String? amount = _extractAmount(body);
      String? merchant = _extractMerchant(body);
      
      if (amount != null) {
        // Update account balance
        await _updateAccountBalanceFromSMS(type, amount);
        
        if (type == "Debited") {
          // Auto-add expense for debited transactions
          await _autoAddExpense(merchant ?? "SMS Transaction", amount, body);
        }
      }
      
      // Show notification
      String transaction = "$type ${amount ?? ""} ${merchant != null ? "to $merchant" : ""}";
      setState(() {
        lastTransaction = transaction;
      });

      _showNotification(transaction);
      
    } catch (e) {
      print("Error processing SMS: $e");
    }
  }

  Future<void> _updateAccountBalanceFromSMS(String type, String amount) async {
    try {
      final numericAmount = double.tryParse(amount.replaceAll(RegExp(r'[^\d.]'), ''));
      if (numericAmount == null || numericAmount <= 0) return;
      
      final prefs = await SharedPreferences.getInstance();
      double currentBalance = prefs.getDouble('accountBalance') ?? 50000.0;
      
      if (type == "Credited") {
        currentBalance += numericAmount;
      } else if (type == "Debited") {
        currentBalance -= numericAmount;
      }
      
      await prefs.setDouble('accountBalance', currentBalance);
      print("💰 Balance updated: ₹${currentBalance.toStringAsFixed(2)}");
      
      // Show balance update notification
      await _showBalanceUpdateNotification(type, numericAmount, currentBalance);
      
    } catch (e) {
      print("Error updating balance: $e");
    }
  }

  Future<void> _showBalanceUpdateNotification(String type, double amount, double newBalance) async {
    if (!kIsWeb) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'balance_update_channel',
        'Balance Updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      String message = type == "Credited" 
          ? "₹${amount.toStringAsFixed(2)} credited. New balance: ₹${newBalance.toStringAsFixed(2)}"
          : "₹${amount.toStringAsFixed(2)} debited. New balance: ₹${newBalance.toStringAsFixed(2)}";

      await notifications.show(
        2,
        'Account Balance Updated',
        message,
        platformDetails,
      );
    }
  }

  Future<void> _autoAddExpense(String title, String amount, String smsBody) async {
    try {
      // Extract numeric amount
      final numericAmount = double.tryParse(amount.replaceAll(RegExp(r'[^\d.]'), ''));
      if (numericAmount == null || numericAmount <= 0) return;
      
      // Determine category based on merchant/SMS content
      String category = _categorizeTransaction(title, smsBody);
      
      // Save to expenses
      final prefs = await SharedPreferences.getInstance();
      String? expensesJson = prefs.getString('expenses');
      List<dynamic> expenses = [];
      
      if (expensesJson != null) {
        expenses = jsonDecode(expensesJson);
      }
      
      // Create new expense
      final newExpense = {
        '_id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'amount': numericAmount,
        'category': category,
        'date': DateTime.now().toIso8601String(),
      };
      
      expenses.insert(0, newExpense);
      
      // Save back
      await prefs.setString('expenses', jsonEncode(expenses));
      
      print("✅ Auto-added expense: $title - ₹$numericAmount");
      
    } catch (e) {
      print("Error auto-adding expense: $e");
    }
  }

  String _categorizeTransaction(String merchant, String smsBody) {
    final lowerMerchant = merchant.toLowerCase();
    final lowerSMS = smsBody.toLowerCase();
    
    // Food & Dining
    if (lowerMerchant.contains('zomato') || 
        lowerMerchant.contains('swiggy') || 
        lowerMerchant.contains('restaurant') ||
        lowerMerchant.contains('food') ||
        lowerSMS.contains('restaurant')) {
      return 'Food';
    }
    
    // Shopping
    if (lowerMerchant.contains('amazon') || 
        lowerMerchant.contains('flipkart') || 
        lowerMerchant.contains('shop') ||
        lowerMerchant.contains('store')) {
      return 'Shopping';
    }
    
    // Transportation
    if (lowerMerchant.contains('uber') || 
        lowerMerchant.contains('ola') || 
        lowerMerchant.contains('petrol') ||
        lowerMerchant.contains('fuel') ||
        lowerSMS.contains('fuel')) {
      return 'Transportation';
    }
    
    // Bills & Utilities
    if (lowerSMS.contains('bill') || 
        lowerSMS.contains('recharge') ||
        lowerSMS.contains('electricity') ||
        lowerSMS.contains('water') ||
        lowerSMS.contains('gas')) {
      return 'Bills';
    }
    
    // Subscriptions
    if (lowerSMS.contains('subscription') || 
        lowerMerchant.contains('netflix') ||
        lowerMerchant.contains('spotify') ||
        lowerMerchant.contains('prime')) {
      return 'Subscription';
    }
    
    return 'Essential'; // Default category
  }

  String? _extractMerchant(String body) {
    // City Union Bank specific patterns
    if (body.toLowerCase().contains('cub') || body.toLowerCase().contains('city union')) {
      // Pattern: "for UPI/SWIGGY*ORDER" or "for AMAZON" etc.
      RegExp cubPattern = RegExp(r'for\s+(?:UPI/)?([A-Za-z0-9\*\s]+)', caseSensitive: false);
      final cubMatch = cubPattern.firstMatch(body);
      if (cubMatch != null && cubMatch.group(1) != null) {
        String merchant = cubMatch.group(1)!.trim();
        merchant = merchant.replaceAll('*', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        if (merchant.length > 2 && merchant.length < 50) {
          return merchant;
        }
      }
    }
    
    // Common patterns for merchant extraction
    final patterns = [
      RegExp(r'at\s+([A-Za-z0-9\s]+)', caseSensitive: false),
      RegExp(r'to\s+([A-Za-z0-9\s]+)', caseSensitive: false),
      RegExp(r'from\s+([A-Za-z0-9\s]+)', caseSensitive: false),
      RegExp(r'paid to\s+([A-Za-z0-9\s]+)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.group(1) != null) {
        String merchant = match.group(1)!.trim();
        // Clean up merchant name
        merchant = merchant.replaceAll(RegExp(r'\s+'), ' ');
        if (merchant.length > 3 && merchant.length < 50) {
          return merchant;
        }
      }
    }
    
    return null;
  }

  String? _extractAmount(String body) {
    // Multiple regex patterns to catch different amount formats
    final patterns = [
      RegExp(r'(?:rs\.?|₹)\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'(\d+(?:,\d+)*(?:\.\d{1,2})?)\s*(?:rs\.?|₹)', caseSensitive: false),
      RegExp(r'amount\s*(?:rs\.?|₹)?\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'inr\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'(?:paid|received|credited|debited)\s*(?:rs\.?|₹)?\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.group(1) != null) {
        String amount = match.group(1)!.replaceAll(',', '');
        final numericAmount = double.tryParse(amount);
        if (numericAmount != null && numericAmount > 0) {
          return numericAmount.toStringAsFixed(2);
        }
      }
    }
    
    return null;
  }

  Future<void> _showNotification(String transaction) async {
    if (!kIsWeb) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'txn_channel',
        'Transactions',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      await notifications.show(
        0,
        'New Transaction',
        transaction,
        platformDetails,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Manager',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/add': (context) => const AddExpenseScreen(),
        '/history': (context) => const HistoryScreen(),
        '/monthly-report': (context) => const MonthlyReportScreen(),
      },
    );
  }
}
