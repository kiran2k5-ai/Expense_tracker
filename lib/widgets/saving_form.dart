import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/saving.dart';

class SavingForm extends StatefulWidget {
  final String userId;
  final Saving? existing;
  final List<String> categories;
  final void Function(String) onNewCategory;

  const SavingForm({
    super.key,
    required this.userId,
    this.existing,
    required this.categories,
    required this.onNewCategory,
  });

  @override
  State<SavingForm> createState() => _SavingFormState();
}

class _SavingFormState extends State<SavingForm> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String category;
  late double targetAmount;
  late double currentAmount;
  late DateTime startDate;
  late DateTime endDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    name = e?.name ?? '';
    category = e?.category ?? widget.categories.first;
    targetAmount = e?.targetAmount ?? 0.0;
    currentAmount = e?.currentAmount ?? 0.0;
    startDate = e?.startDate ?? DateTime.now();
    endDate = e?.endDate ?? DateTime.now().add(const Duration(days: 365));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'userId': widget.userId,
      'name': name,
      'category': category,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };

    final isEdit = widget.existing != null;
    final url = isEdit
        ? Uri.parse('http://localhost:5000/api/savings/${widget.existing!.id}')
        : Uri.parse('http://localhost:5000/api/savings');

    final response = await (isEdit
        ? http.put(url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload))
        : http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload)));

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context, true);
    } else {
      print("Failed: ${response.body}");
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) startDate = picked;
        else endDate = picked;
      });
    }
  }

  Future<void> _addNewCategory() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Custom Category"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Add"),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      widget.onNewCategory(result);
      setState(() {
        category = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (val) => name = val,
                validator: (val) =>
                val == null || val.isEmpty ? 'Enter name' : null,
              ),
              TextFormField(
                initialValue: targetAmount.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target Amount'),
                onChanged: (val) =>
                targetAmount = double.tryParse(val) ?? 0.0,
              ),
              TextFormField(
                initialValue: currentAmount.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Current Amount'),
                onChanged: (val) =>
                currentAmount = double.tryParse(val) ?? 0.0,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: category,
                items: [
                  ...widget.categories.map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  )),
                  const DropdownMenuItem(
                    value: 'add_new',
                    child: Row(
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 8),
                        Text('Add Custom Category'),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val == 'add_new') {
                    _addNewCategory();
                  } else if (val != null) {
                    setState(() => category = val);
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text("Start: "),
                  TextButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text(startDate.toString().split(' ')[0]),
                  ),
                  const Text("End: "),
                  TextButton(
                    onPressed: () => _pickDate(isStart: false),
                    child: Text(endDate.toString().split(' ')[0]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _submit,
                child: Text(widget.existing != null ? 'Update' : 'Add'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
