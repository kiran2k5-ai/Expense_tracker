import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  List<Expense> filteredExpenses = [];
  bool isLoading = false;
  DateTime selectedDate = DateTime.now();
  double totalMonthlySpend = 0.0;

  @override
  void initState() {
    super.initState();
    fetchMonthlyExpenses(selectedDate);
  }

  /// Fetch expenses for a specific month from the backend API
  Future<void> fetchMonthlyExpenses(DateTime date) async {
    setState(() => isLoading = true);

    try {
      // Get authentication token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        Fluttertoast.showToast(msg: "No token found. Please log in.");
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // Make API request to fetch expenses
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/expenses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Parse the response and convert to Expense objects
        final List<dynamic> expensesJson = jsonDecode(response.body);
        final allExpenses =
            expensesJson.map((e) => Expense.fromJson(e)).toList();

        // Filter expenses to only include those from the selected month and year
        final monthlyExpenses = allExpenses.where((expense) {
          return expense.date.year == date.year &&
              expense.date.month == date.month;
        }).toList();

        // Sort expenses by date in descending order
        monthlyExpenses.sort((a, b) => b.date.compareTo(a.date));

        // Calculate total monthly spend
        final total =
            monthlyExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

        setState(() {
          filteredExpenses = monthlyExpenses;
          totalMonthlySpend = total;
          isLoading = false;
        });
      } else {
        Fluttertoast.showToast(msg: 'Failed to load expenses');
        setState(() => isLoading = false);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching expenses: $e');
      setState(() => isLoading = false);
    }
  }

  /// Show month and year picker dialog
  Future<void> showMonthYearPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        selectedDate = DateTime(picked.year, picked.month, 1);
      });
      await fetchMonthlyExpenses(selectedDate);
    }
  }

  /// Format date to show day and day of week (e.g., "15 Mon")
  String formatExpenseDate(DateTime date) {
    return DateFormat('d EEE').format(date);
  }

  /// Format month and year for display (e.g., "September 2025")
  String formatSelectedMonth() {
    return DateFormat('MMMM yyyy').format(selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Expense Report'),
        backgroundColor: Colors.deepPurple,
        actions: [
          // Month selector button in AppBar
          TextButton(
            onPressed: showMonthYearPicker,
            child: Text(
              formatSelectedMonth(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Total Spent Card
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.withOpacity(0.8),
                          Colors.deepPurple
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Spent',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${totalMonthlySpend.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatSelectedMonth(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expenses List
                Expanded(
                  child: filteredExpenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No expenses found for ${formatSelectedMonth()}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add some expenses to see your monthly report',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = filteredExpenses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Colors.deepPurple.withOpacity(0.1),
                                  child: Text(
                                    formatExpenseDate(expense.date)
                                        .split(' ')[0], // Day number
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  expense.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.category,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          expense.category,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          formatExpenseDate(expense.date)
                                              .split(' ')[1], // Day of week
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  '₹${expense.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
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
}
