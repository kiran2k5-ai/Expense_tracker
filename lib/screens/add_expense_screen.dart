import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  double? amount;
  String category = 'Essential';
  DateTime selectedDate = DateTime.now();

  final List<String> categories = [
    'Essential',
    'Waste of Money',
    'Compulsory',
    'Food',
    'Shopping',
    'Subscription',
    'Bills',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      title = widget.expense!.title;
      amount = widget.expense!.amount;
      category = widget.expense!.category;
      selectedDate = widget.expense!.date;
      if (!categories.contains(category)) {
        categories.add(category);
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load existing expenses
      String? expensesJson = prefs.getString('expenses');
      List<Expense> expenses = [];
      if (expensesJson != null) {
        List<dynamic> expensesList = jsonDecode(expensesJson);
        expenses = expensesList.map((e) => Expense.fromJson(e)).toList();
      }

      final isEditing = widget.expense != null;
      
      if (isEditing) {
        // Update existing expense
        int index = expenses.indexWhere((e) => e.id == widget.expense!.id);
        if (index != -1) {
          expenses[index] = Expense(
            id: widget.expense!.id,
            title: title.trim(),
            amount: amount!,
            category: category,
            date: selectedDate,
          );
        }
      } else {
        // Add new expense
        final newExpense = Expense(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title.trim(),
          amount: amount!,
          category: category,
          date: selectedDate,
        );
        expenses.insert(0, newExpense); // Insert at beginning for recent first
      }

      // Save back to local storage
      String updatedExpensesJson = jsonEncode(expenses.map((e) => e.toJson()).toList());
      await prefs.setString('expenses', updatedExpensesJson);

      Fluttertoast.showToast(
          msg: isEditing ? "Expense updated!" : "Expense added!");
      if (mounted) Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  Future<String?> _showAddCategoryDialog() async {
    String newCategory = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Custom Category"),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Enter category name",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => newCategory = value,
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Add"),
            onPressed: () => Navigator.pop(context, newCategory),
          ),
        ],
      ),
    );
  }

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Expense" : "Add Expense"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        color: const Color(0xFFF3F3F3),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(16),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: title,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (val) => title = val,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Enter a title'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: amount?.toString(),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) amount = parsed;
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Enter amount';
                          final parsed = double.tryParse(val);
                          if (parsed == null || parsed <= 0) {
                            return 'Enter valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: category,
                        items: [
                          ...categories.map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 6,
                                  backgroundColor: _getCategoryColor(cat),
                                ),
                                const SizedBox(width: 8),
                                Text(cat),
                              ],
                            ),
                          )),
                          const DropdownMenuItem(
                            value: 'add_new_category',
                            child: Row(
                              children: [
                                Icon(Icons.add, color: Colors.deepPurple),
                                SizedBox(width: 8),
                                Text("Add Custom Category"),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) async {
                          if (val == 'add_new_category') {
                            final newCategory = await _showAddCategoryDialog();
                            if (newCategory != null &&
                                newCategory.trim().isNotEmpty) {
                              setState(() {
                                categories.add(newCategory.trim());
                                category = newCategory.trim();
                              });
                            }
                          } else {
                            setState(() => category = val!);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "${selectedDate.toLocal().toString().split(' ')[0]}",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.date_range),
                            label: const Text("Pick Date"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            isEditing ? Icons.update : Icons.add,
                            color: Colors.white,
                          ),
                          label: Text(
                            isEditing ? "Update Expense" : "Add Expense",
                            style: const TextStyle(color: Colors.white),
                          ),
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
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
      case 'Bills':
        return Colors.teal.shade200;
      case 'Shopping':
        return Colors.red.shade200;
      default:
        return Colors.grey.shade300;
    }
  }
}
