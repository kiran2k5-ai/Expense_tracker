import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../models/expense.dart';
import '../widgets/summary_card.dart';
import '../widgets/chart_switcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Expense> expenses = [];
  bool isLoading = true;
  double monthlyBudget = 0.0;

  @override
  void initState() {
    super.initState();
    fetchProfile();
    fetchExpenses(); // your existing code
  }

  Future<void> fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('http://localhost:5000/api/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final profileData = jsonDecode(response.body);
        setState(() {
          monthlyBudget = profileData['monthlyBudget']?.toDouble() ?? 0.0;
        });
      } else {
        print('Failed to load profile in dashboard: ${response.body}');
      }
    } catch (e) {
      print('Error fetching profile in dashboard: $e');
    }
  }

//      Uri.parse('http://localhost:5000/api/auth/profile'),
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
        setState(() {
          expenses = (jsonDecode(response.body) as List)
              .map((e) => Expense.fromJson(e))
              .toList();
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
        title: const Text('Expense Dashboard'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment),
            onPressed: () {
              Navigator.pushNamed(context, 'monthly-report');
            },
            tooltip: 'Monthly Report',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchExpenses,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Summary Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SummaryCard(
                        title: 'Today\'s Spend',
                        amount: '₹${todaySpend.toStringAsFixed(2)}',
                        icon: Icons.today,
                        color: Colors.blue,
                      ),
                      SummaryCard(
                        title: 'Top Category',
                        amount: topCategory,
                        icon: Icons.local_dining,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SummaryCard(
                    title: 'Budget Usage',
                    amount:
                        '₹${monthlyTotal.toStringAsFixed(0)} / ₹${monthlyBudget.toStringAsFixed(0)}',
                    icon: Icons.trending_up,
                    color: Colors.green,
                    fullWidth: true,
                  ),

                  const SizedBox(height: 24),
                  // Chart Switcher
                  ChartSwitcher(expenses: expenses),
                ],
              ),
            ),
    );
  }
}
