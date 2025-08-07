import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/main_scaffold.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ✅ Clean UI
      title: 'Expense Manager',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      initialRoute: '/login', // ✅ Default route
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),

        '/add': (context) => const AddExpenseScreen(),
      },
    );
  }
}
