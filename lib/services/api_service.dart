import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense.dart';

class ApiService {
  static const String baseUrl = "http://localhost:5000/api/expenses";
  // Use http://localhost:5000 on web
  // Use http://10.0.2.2:5000 on Android Emulator
  // Use your local IP (like http://192.168.x.x:5000) on real device

  // Fetch all expenses
  static Future<List<Expense>> getExpenses() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List jsonData = json.decode(response.body);
      return jsonData.map((e) => Expense.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load expenses");
    }
  }

  // Add a new expense
  static Future<Expense> addExpense(Expense expense) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(expense.toJson()),
    );

    if (response.statusCode == 201) {
      return Expense.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to add expense");
    }
  }
}
