import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/expense.dart';
import '../widgets/chart_switcher.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/monthly_bar_chart.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Expense> expenses = [];
  bool isLoading = true;
  double monthlyBudget = 15000.0; // Default budget
  double accountBalance = 50000.0; // Default account balance
  String userName = 'Kiran';

  // Notification plugin instance
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    loadLocalData();
  }

  // Initialize notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _notifications.initialize(initializationSettings);
  }

  // Test notification function
  Future<void> _testNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      0,
      '🎉 Test Notification',
      'Your expense tracker notifications are working perfectly! Current balance: ₹${accountBalance.toStringAsFixed(2)}',
      platformDetails,
    );
    
    Fluttertoast.showToast(msg: 'Test notification sent!');
  }

  Future<void> loadLocalData() async {
    setState(() => isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load user data from local storage
      userName = prefs.getString('userName') ?? 'Kiran';
      monthlyBudget = prefs.getDouble('monthlyBudget') ?? 15000.0;
      accountBalance = prefs.getDouble('accountBalance') ?? 50000.0;
      
      // Load expenses from local storage
      String? expensesJson = prefs.getString('expenses');
      if (expensesJson != null) {
        List<dynamic> expensesList = jsonDecode(expensesJson);
        expenses = expensesList.map((e) => Expense.fromJson(e)).toList();
      } else {
        // Create some sample data for demonstration
        expenses = [
          Expense(
            id: '1',
            title: 'Grocery Shopping',
            amount: 2500.0,
            category: 'Food',
            date: DateTime.now().subtract(const Duration(days: 1)),
          ),
          Expense(
            id: '2',
            title: 'Fuel',
            amount: 3000.0,
            category: 'Transportation',
            date: DateTime.now().subtract(const Duration(days: 2)),
          ),
          Expense(
            id: '3',
            title: 'Coffee',
            amount: 150.0,
            category: 'Food',
            date: DateTime.now(),
          ),
        ];
        // Save sample data to local storage
        await saveExpensesToLocal();
      }
      
      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading local data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> saveExpensesToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String expensesJson = jsonEncode(expenses.map((e) => e.toJson()).toList());
      await prefs.setString('expenses', expensesJson);
    } catch (e) {
      print('Error saving expenses: $e');
    }
  }

  Future<void> refreshData() async {
    await loadLocalData();
    Fluttertoast.showToast(msg: 'Data refreshed');
  }

  Future<void> _updateAccountBalance() async {
    TextEditingController balanceController = TextEditingController();
    balanceController.text = accountBalance.toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Account Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Balance: ₹${accountBalance.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Balance',
                prefixText: '₹',
                border: OutlineInputBorder(),
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
              final newBalance = double.tryParse(balanceController.text);
              if (newBalance != null && newBalance >= 0) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setDouble('accountBalance', newBalance);
                setState(() {
                  accountBalance = newBalance;
                });
                Fluttertoast.showToast(msg: 'Account balance updated!');
                Navigator.pop(context);
              } else {
                Fluttertoast.showToast(msg: 'Please enter a valid amount');
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  double getTodaySpend() {
    final today = DateTime.now();
    return expenses
        .where((e) =>
            e.date.year == today.year &&
            e.date.month == today.month &&
            e.date.day == today.day)
        .fold(0, (sum, e) => sum + e.amount);
  }

  String getTopCategory() {
    final Map<String, double> categoryTotals = {};
    final now = DateTime.now();
    for (var e in expenses) {
      if (e.date.year == now.year && e.date.month == now.month) {
        categoryTotals[e.category] =
            (categoryTotals[e.category] ?? 0) + e.amount;
      }
    }

    if (categoryTotals.isEmpty) return "N/A";

    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  double getMonthlySpend() {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0, (sum, e) => sum + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    final todaySpend = getTodaySpend();
    final topCategory = getTopCategory();
    final monthlyTotal = getMonthlySpend();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, $userName!'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/history');
              if (result == true) {
                loadLocalData(); // Refresh if any changes were made
              }
            },
            tooltip: 'View History',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/add');
              if (result == true) {
                loadLocalData(); // Refresh if expense was added
              }
            },
            tooltip: 'Add Expense',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('isLoggedIn');
                await prefs.remove('user_pin');
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              } else if (value == 'updateBalance') {
                _updateAccountBalance();
              } else if (value == 'settings') {
                _showSettingsDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'updateBalance',
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.black87),
                    SizedBox(width: 8),
                    Text('Update Balance'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.black87),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.black87),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Today\'s Spend',
                          '₹${todaySpend.toStringAsFixed(0)}',
                          Icons.today,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Top Category',
                          topCategory,
                          Icons.local_dining,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Account Balance Card
                  GestureDetector(
                    onTap: _updateAccountBalance,
                    child: _buildSummaryCard(
                      'Account Balance',
                      '₹${accountBalance.toStringAsFixed(0)}',
                      Icons.account_balance_wallet,
                      Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSummaryCard(
                    'Monthly Budget',
                    '₹${monthlyTotal.toStringAsFixed(0)} / ₹${monthlyBudget.toStringAsFixed(0)}',
                    Icons.trending_up,
                    monthlyTotal > monthlyBudget ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 24),
                  
                  // Charts Section
                  if (expenses.isNotEmpty) ...[
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ChartSwitcher(expenses: expenses),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Recent Expenses
                  const Text(
                    'Recent Expenses',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  expenses.isEmpty
                      ? const Center(
                          child: Text(
                            'No expenses yet. Add your first expense!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: expenses.length > 5 ? 5 : expenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenses[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getCategoryColor(expense.category),
                                  child: Icon(
                                    _getCategoryIcon(expense.category),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(expense.title),
                                subtitle: Text(
                                  '${expense.category} • ${_formatDate(expense.date)}',
                                ),
                                trailing: Text(
                                  '₹${expense.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add');
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transportation':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'bills':
        return Colors.red;
      case 'health':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt;
      case 'health':
        return Icons.local_hospital;
      default:
        return Icons.category;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    
    if (diff == 0) {
      return 'Today';
    } else if (diff == 1) {
      return 'Yesterday';
    } else if (diff < 7) {
      return '$diff days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _showSettingsDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('User: $userName'),
              trailing: const Icon(Icons.edit),
              onTap: () => _updateUserName(),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: Text('Balance: ₹${accountBalance.toStringAsFixed(2)}'),
              trailing: const Icon(Icons.edit),
              onTap: () {
                Navigator.pop(context);
                _updateAccountBalance();
              },
            ),
            ListTile(
              leading: const Icon(Icons.savings),
              title: Text('Budget: ₹${monthlyBudget.toStringAsFixed(0)}'),
              trailing: const Icon(Icons.edit),
              onTap: () => _updateMonthlyBudget(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_active, color: Colors.orange),
              title: const Text('Test Notifications'),
              subtitle: const Text('Send a test notification'),
              trailing: const Icon(Icons.send),
              onTap: () {
                Navigator.pop(context);
                _testNotification();
              },
            ),
            ListTile(
              leading: const Icon(Icons.sms, color: Colors.green),
              title: const Text('Test SMS Banking'),
              subtitle: const Text('Simulate bank SMS messages'),
              trailing: const Icon(Icons.message),
              onTap: () {
                Navigator.pop(context);
                _showSMSTestDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserName() async {
    TextEditingController nameController = TextEditingController();
    nameController.text = userName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Your Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('userName', nameController.text.trim());
                setState(() {
                  userName = nameController.text.trim();
                });
                Fluttertoast.showToast(msg: 'Name updated!');
                Navigator.pop(context);
                Navigator.pop(context); // Close settings dialog too
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMonthlyBudget() async {
    TextEditingController budgetController = TextEditingController();
    budgetController.text = monthlyBudget.toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Monthly Budget'),
        content: TextField(
          controller: budgetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monthly Budget',
            prefixText: '₹',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBudget = double.tryParse(budgetController.text);
              if (newBudget != null && newBudget > 0) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setDouble('monthlyBudget', newBudget);
                setState(() {
                  monthlyBudget = newBudget;
                });
                Fluttertoast.showToast(msg: 'Budget updated!');
                Navigator.pop(context);
                Navigator.pop(context); // Close settings dialog too
              } else {
                Fluttertoast.showToast(msg: 'Please enter a valid amount');
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSMSTestDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.sms, color: Colors.green),
            SizedBox(width: 8),
            Text('SMS Banking Test'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a bank SMS message to simulate:'),
            const SizedBox(height: 16),
            _buildSMSTestButton(
              'HDFC Bank - Debit',
              'Your A/c XXXXXXX1234 has been debited with Rs.1,500.00 on 03-OCT-25 at AMAZON. Current balance: Rs.48,500.00.',
              Icons.remove_circle,
              Colors.red.shade600,
            ),
            _buildSMSTestButton(
              'SBI - Credit',
              'Dear Customer, Rs.5,000.00 has been credited to your SBI A/c XX1234 on 03-OCT-25. Available balance: Rs.53,500.00.',
              Icons.add_circle,
              Colors.green.shade600,
            ),
            _buildSMSTestButton(
              'City Union Bank - Debit',
              'Dear Customer, Your A/c XX1234 is debited with Rs.2,500.00 on 03-Oct-25 for UPI/SWIGGY*ORDER. Available balance: Rs.47,500.00. -CUB',
              Icons.remove_circle_outline,
              Colors.blue.shade600,
            ),
            _buildSMSTestButton(
              'City Union Bank - Credit',
              'Dear Customer, Your A/c XX1234 is credited with Rs.10,000.00 on 03-Oct-25. Available balance: Rs.57,500.00. Thank you for banking with CUB.',
              Icons.add_circle_outline,
              Colors.teal.shade600,
            ),
            _buildSMSTestButton(
              'ICICI - UPI Payment',
              'Rs.850.00 paid to SWIGGY via UPI from ICICI Bank A/c XX1234. Txn ID: 425692158963.',
              Icons.payment,
              Colors.orange.shade600,
            ),
            _buildSMSTestButton(
              'Axis Bank - ATM Withdrawal',
              'Rs.2,000.00 withdrawn from your Axis Bank A/c XX1234 at ATM 425968 on 03-OCT-25.',
              Icons.local_atm,
              Colors.purple.shade600,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSMSTestButton(String title, String smsMessage, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.15),
          foregroundColor: Color.lerp(color, Colors.black, 0.3),
          minimumSize: const Size(double.infinity, 58),
          alignment: Alignment.centerLeft,
          elevation: 3,
          shadowColor: color.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
          _simulateBankSMS(smsMessage, title);
        },
        icon: Icon(icon, size: 26),
        label: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _simulateBankSMS(String smsMessage, String bankName) async {
    try {
      Fluttertoast.showToast(
        msg: '📱 Simulating SMS from $bankName...',
        toastLength: Toast.LENGTH_SHORT,
      );

      // Wait a moment to simulate SMS arrival
      await Future.delayed(const Duration(milliseconds: 500));

      // Process the SMS like a real bank message
      await _processBankSMS(smsMessage);

      // Show success notification
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '📱 Bank SMS Processed',
        'Successfully processed: $bankName transaction',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'sms_test_channel',
            'SMS Test Notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );

    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error simulating SMS: $e',
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Future<void> _processBankSMS(String smsBody) async {
    try {
      final lowerBody = smsBody.toLowerCase();
      
      // Determine transaction type
      String type = "Debited";
      if (lowerBody.contains("credited") || lowerBody.contains("credit")) {
        type = "Credited";
      }
      
      // Extract amount using regex
      String? amount = _extractAmountFromSMS(smsBody);
      String? merchant = _extractMerchantFromSMS(smsBody);
      
      if (amount != null) {
        // Update account balance
        await _updateAccountBalanceFromSMS(type, amount);
        
        if (type == "Debited") {
          // Auto-add expense for debited transactions
          await _autoAddExpenseFromSMS(merchant ?? "SMS Transaction", amount, smsBody);
        }
        
        // Show transaction notification
        String transactionInfo = "$type ₹$amount${merchant != null ? " to $merchant" : ""}";
        
        await _notifications.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1,
          '💰 Transaction Detected',
          transactionInfo,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'transaction_channel',
              'Transaction Notifications',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              color: Colors.blue,
            ),
          ),
        );
        
        Fluttertoast.showToast(
          msg: '✅ Transaction processed: $transactionInfo',
          toastLength: Toast.LENGTH_LONG,
        );
        
        // Refresh dashboard data
        setState(() {
          // This will trigger a rebuild which will reload the data
        });
      }
      
    } catch (e) {
      print("Error processing bank SMS: $e");
      Fluttertoast.showToast(
        msg: 'Error processing SMS: $e',
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  String? _extractAmountFromSMS(String sms) {
    // Regex patterns to match different amount formats
    final patterns = [
      r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)', // Rs.1,500.00 or Rs 1500
      r'INR\s*(\d+(?:,\d+)*(?:\.\d{2})?)',  // INR 1500
      r'₹\s*(\d+(?:,\d+)*(?:\.\d{2})?)',    // ₹1500
      r'(\d+(?:,\d+)*(?:\.\d{2})?)\s*(?:rupees?|rs\.?)', // 1500 rupees
    ];
    
    for (String pattern in patterns) {
      RegExp regex = RegExp(pattern, caseSensitive: false);
      Match? match = regex.firstMatch(sms);
      if (match != null) {
        return match.group(1)?.replaceAll(',', '');
      }
    }
    return null;
  }

  String? _extractMerchantFromSMS(String sms) {
    final lowerSms = sms.toLowerCase();
    
    // Common merchant patterns
    final merchantPatterns = {
      'amazon': 'Amazon',
      'swiggy': 'Swiggy',
      'zomato': 'Zomato',
      'uber': 'Uber',
      'ola': 'Ola',
      'flipkart': 'Flipkart',
      'myntra': 'Myntra',
      'paytm': 'Paytm',
      'gpay': 'Google Pay',
      'phonepe': 'PhonePe',
      'walmart': 'Walmart',
      'bigbasket': 'BigBasket',
      'grofers': 'Grofers',
      'reliance': 'Reliance',
      'jio': 'Jio',
      'airtel': 'Airtel',
    };
    
    for (String key in merchantPatterns.keys) {
      if (lowerSms.contains(key)) {
        return merchantPatterns[key];
      }
    }
    
    // Try to extract merchant from "paid to" or "at" patterns
    RegExp atPattern = RegExp(r'\bat\s+([A-Z][A-Z\s]+?)(?:\s+on|\.|$)', caseSensitive: false);
    Match? atMatch = atPattern.firstMatch(sms);
    if (atMatch != null) {
      return atMatch.group(1)?.trim();
    }
    
    RegExp toPattern = RegExp(r'paid to\s+([A-Z][A-Z\s]+?)(?:\s+via|\.|$)', caseSensitive: false);
    Match? toMatch = toPattern.firstMatch(sms);
    if (toMatch != null) {
      return toMatch.group(1)?.trim();
    }
    
    return null;
  }

  Future<void> _updateAccountBalanceFromSMS(String type, String amount) async {
    try {
      final numericAmount = double.tryParse(amount);
      if (numericAmount == null || numericAmount <= 0) return;
      
      final prefs = await SharedPreferences.getInstance();
      double currentBalance = prefs.getDouble('accountBalance') ?? 50000.0;
      
      if (type == "Credited") {
        currentBalance += numericAmount;
      } else if (type == "Debited") {
        currentBalance -= numericAmount;
      }
      
      await prefs.setDouble('accountBalance', currentBalance);
      print("💰 Balance updated from SMS: ₹${currentBalance.toStringAsFixed(2)}");
      
      // Update the UI
      setState(() {
        accountBalance = currentBalance;
      });
      
      // Show balance update notification
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + 2,
        '💰 Account Balance Updated',
        type == "Credited" 
            ? "₹${numericAmount.toStringAsFixed(2)} credited. New balance: ₹${currentBalance.toStringAsFixed(2)}"
            : "₹${numericAmount.toStringAsFixed(2)} debited. New balance: ₹${currentBalance.toStringAsFixed(2)}",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'balance_update_channel',
            'Balance Updates',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Colors.green,
          ),
        ),
      );
      
    } catch (e) {
      print("Error updating balance from SMS: $e");
    }
  }

  Future<void> _autoAddExpenseFromSMS(String merchant, String amount, String smsBody) async {
    try {
      final numericAmount = double.tryParse(amount);
      if (numericAmount == null || numericAmount <= 0) return;
      
      // Determine category based on merchant
      String category = _categorizeMerchant(merchant);
      
      // Save the expense
      final prefs = await SharedPreferences.getInstance();
      List<String> expenses = prefs.getStringList('expenses') ?? [];
      
      final expense = {
        'amount': numericAmount,
        'category': category,
        'description': 'SMS: $merchant',
        'date': DateTime.now().toIso8601String(),
        'isAutoAdded': true,
      };
      
      expenses.add(jsonEncode(expense));
      await prefs.setStringList('expenses', expenses);
      
      print("💸 Auto-added expense: ₹$amount for $merchant in $category");
      
      // Show auto-expense notification
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3,
        '📱 Auto-Added Expense',
        '₹$amount spent at $merchant (Category: $category)',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'auto_expense_channel',
            'Auto-Added Expenses',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Colors.orange,
          ),
        ),
      );
      
    } catch (e) {
      print("Error auto-adding expense from SMS: $e");
    }
  }

  String _categorizeMerchant(String merchant) {
    final lowerMerchant = merchant.toLowerCase();
    
    if (lowerMerchant.contains('amazon') || lowerMerchant.contains('flipkart') || 
        lowerMerchant.contains('myntra') || lowerMerchant.contains('walmart')) {
      return 'Shopping';
    } else if (lowerMerchant.contains('swiggy') || lowerMerchant.contains('zomato')) {
      return 'Food';
    } else if (lowerMerchant.contains('uber') || lowerMerchant.contains('ola')) {
      return 'Transport';
    } else if (lowerMerchant.contains('jio') || lowerMerchant.contains('airtel')) {
      return 'Bills';
    } else if (lowerMerchant.contains('bigbasket') || lowerMerchant.contains('grofers')) {
      return 'Groceries';
    } else if (lowerMerchant.contains('atm')) {
      return 'Cash Withdrawal';
    } else {
      return 'Others';
    }
  }
}
