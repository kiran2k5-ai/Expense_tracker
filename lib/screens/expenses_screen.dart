import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Expense> expenses = [];
  bool isLoading = true;

  DateTimeRange? selectedRange;

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      Fluttertoast.showToast(msg: "No token found. Please log in.");
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/expenses'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = (jsonDecode(response.body) as List)
            .map((e) => Expense.fromJson(e))
            .toList();

        setState(() {
          expenses = data;
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

  Future<void> _deleteExpense(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/expenses/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "Expense deleted");
        fetchExpenses();
      } else {
        Fluttertoast.showToast(msg: "Failed to delete");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  Color categoryColor(String category) {
    switch (category) {
      case 'Essential':
        return Colors.green.shade100;
      case 'Waste of Money':
        return Colors.red.shade100;
      case 'Compulsory':
        return Colors.orange.shade100;
      case 'Food':
        return Colors.blue.shade100;
      case 'Subscription':
        return Colors.purple.shade200;
      case 'Shopping':
        return Colors.red.shade200;
      case 'Bills':
        return Colors.teal.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  List<Expense> get filteredExpenses {
    if (selectedRange == null) return expenses;

    return expenses.where((exp) {
      final date = exp.date;
      return date.isAfter(selectedRange!.start.subtract(const Duration(days: 1))) &&
          date.isBefore(selectedRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  Map<String, List<Expense>> groupExpensesByDate(List<Expense> list) {
    final Map<String, List<Expense>> grouped = {};

    for (var expense in list) {
      final dateKey = DateFormat('yyyy-MM-dd').format(expense.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(expense);
    }

    // Sort by newest date first
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final sortedMap = {
      for (var key in sortedKeys) key: grouped[key]!,
    };

    return sortedMap;
  }

  Widget buildExpenseCard(Expense exp) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: categoryColor(exp.category),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${exp.category} • ₹${exp.amount.toStringAsFixed(2)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddExpenseScreen(expense: exp)),
                ).then((_) => fetchExpenses());
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteExpense(exp.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: selectedRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );

    if (picked != null) {
      setState(() {
        selectedRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupExpensesByDate(filteredExpenses);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Expenses'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            onPressed: pickDateRange,
            icon: const Icon(Icons.date_range),
            tooltip: "Filter by Date Range",
          ),
          if (selectedRange != null)
            IconButton(
              onPressed: () => setState(() => selectedRange = null),
              icon: const Icon(Icons.clear),
              tooltip: "Clear Filter",
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : grouped.isEmpty
          ? const Center(child: Text('No expenses found'))
          : ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: grouped.entries.map((entry) {
          final date = entry.key;
          final items = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Text(
                  DateFormat.yMMMMd().format(DateTime.parse(date)),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...items.map(buildExpenseCard).toList(),
            ],
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          ).then((_) => fetchExpenses());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
