import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/expense.dart';
import 'dashboard_screen.dart';
import 'expenses_screen.dart';
import 'insights_screen.dart';
import 'savings_screen.dart';
import 'profile_screen.dart';

class MainScaffold extends StatefulWidget {
  final String userId;

  const MainScaffold({super.key, required this.userId});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  List<Expense> _expenses = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/expenses/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          final List<dynamic> jsonList = json.decode(response.body);
          setState(() {
            _expenses = jsonList.map((e) => Expense.fromJson(e)).toList();
            _isLoading = false;
          });

        });
      } else {
        print('Failed to fetch expenses');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching expenses: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Widget> get _screens => [
    const DashboardScreen(),
    const ExpensesScreen(),
    InsightsScreen(expenses: _expenses),
    SavingsScreen(userId: widget.userId),
    const ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Expenses'),
    BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Insights'),
    BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Savings'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTap,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: _navItems,
      ),
    );
  }
}
