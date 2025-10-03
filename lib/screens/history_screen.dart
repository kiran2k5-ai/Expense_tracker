import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import '../models/expense.dart';
import 'add_expense_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Expense> expenses = [];
  List<Expense> filteredExpenses = [];
  bool isLoading = true;
  String selectedFilter = 'All';
  String selectedCategory = 'All';

  final List<String> filters = ['All', 'Today', 'This Week', 'This Month', 'This Year'];
  final List<String> categories = ['All', 'Essential', 'Waste of Money', 'Compulsory', 'Food', 'Shopping', 'Subscription', 'Bills'];

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    setState(() => isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      String? expensesJson = prefs.getString('expenses');
      
      if (expensesJson != null) {
        List<dynamic> expensesList = jsonDecode(expensesJson);
        expenses = expensesList.map((e) => Expense.fromJson(e)).toList();
        // Sort by date (newest first)
        expenses.sort((a, b) => b.date.compareTo(a.date));
      }
      
      _applyFilters();
      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading expenses: $e');
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    filteredExpenses = expenses.where((expense) {
      // Date filter
      bool dateMatch = true;
      final now = DateTime.now();
      
      switch (selectedFilter) {
        case 'Today':
          dateMatch = expense.date.year == now.year &&
                     expense.date.month == now.month &&
                     expense.date.day == now.day;
          break;
        case 'This Week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          dateMatch = expense.date.isAfter(startOfWeek.subtract(const Duration(days: 1)));
          break;
        case 'This Month':
          dateMatch = expense.date.year == now.year && expense.date.month == now.month;
          break;
        case 'This Year':
          dateMatch = expense.date.year == now.year;
          break;
        default:
          dateMatch = true;
      }
      
      // Category filter
      bool categoryMatch = selectedCategory == 'All' || expense.category == selectedCategory;
      
      return dateMatch && categoryMatch;
    }).toList();
  }

  Future<void> _deleteExpense(String expenseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      expenses.removeWhere((e) => e.id == expenseId);
      
      String updatedExpensesJson = jsonEncode(expenses.map((e) => e.toJson()).toList());
      await prefs.setString('expenses', updatedExpensesJson);
      
      _applyFilters();
      setState(() {});
      Fluttertoast.showToast(msg: "Expense deleted!");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error deleting expense: $e");
    }
  }

  Future<void> _editExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(expense: expense),
      ),
    );
    
    if (result == true) {
      loadExpenses(); // Reload if expense was updated
    }
  }

  double _getTotalAmount() {
    return filteredExpenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense History'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadExpenses,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                // Date Filter
                Row(
                  children: [
                    const Icon(Icons.date_range, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    const Text('Period: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedFilter,
                        isExpanded: true,
                        items: filters.map((filter) => DropdownMenuItem(
                          value: filter,
                          child: Text(filter),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedFilter = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Category Filter
                Row(
                  children: [
                    const Icon(Icons.category, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    const Text('Category: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        items: categories.map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                // Total Amount
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${_getTotalAmount().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Expenses List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No expenses found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters or add some expenses',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = filteredExpenses[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getCategoryColor(expense.category),
                                child: Icon(
                                  _getCategoryIcon(expense.category),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                expense.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense.category,
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                  Text(
                                    _formatDate(expense.date),
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${expense.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editExpense(expense);
                                      } else if (value == 'delete') {
                                        _showDeleteConfirmation(expense);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteExpense(expense.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'essential':
        return Colors.green;
      case 'waste of money':
        return Colors.red;
      case 'compulsory':
        return Colors.orange;
      case 'food':
        return Colors.blue;
      case 'shopping':
        return Colors.pink;
      case 'subscription':
        return Colors.purple;
      case 'bills':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'essential':
        return Icons.star;
      case 'waste of money':
        return Icons.money_off;
      case 'compulsory':
        return Icons.assignment;
      case 'food':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'subscription':
        return Icons.subscriptions;
      case 'bills':
        return Icons.receipt;
      default:
        return Icons.category;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    
    if (diff == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff == 1) {
      return 'Yesterday';
    } else if (diff < 7) {
      return '$diff days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}