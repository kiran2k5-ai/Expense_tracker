import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../models/expense.dart';

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

  @override
  void initState() {
    super.initState();
    loadLocalData();
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
                    Icon(Icons.account_balance_wallet),
                    SizedBox(width: 8),
                    Text('Update Balance'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
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
}
