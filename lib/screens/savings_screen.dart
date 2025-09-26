import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/saving.dart';
import '../widgets/saving_form.dart';

class SavingsScreen extends StatefulWidget {
  final String userId;

  const SavingsScreen({super.key, required this.userId});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  List<Saving> savings = [];
  List<String> categories = ['LIC', 'Chit Fund', 'Fixed Deposit', 'Post Office Account'];

  @override
  void initState() {
    super.initState();
    fetchSavings();
  }

  Future<void> fetchSavings() async {
    final url = Uri.parse('http://localhost:5000/api/savings/${widget.userId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        savings = data.map((e) => Saving.fromJson(e)).toList();
      });
    } else {
      debugPrint("Failed to fetch savings: ${response.statusCode}");
    }
  }

  Future<void> deleteSaving(String id) async {
    final url = Uri.parse('http://localhost:5000/api/savings/$id');
    final res = await http.delete(url);
    if (res.statusCode == 204) {
      fetchSavings();
    }
  }

  void showSavingForm({Saving? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SavingForm(
          userId: widget.userId,
          existing: existing,
          categories: categories,
          onNewCategory: (cat) {
            if (!categories.contains(cat)) {
              setState(() => categories.add(cat));
            }
          },
        ),
      ),
    );

    if (result == true) {
      fetchSavings();
    }
  }

  double get totalSaved => savings.fold(0.0, (sum, s) => sum + s.currentAmount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("💰 My Savings"),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.green[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Total Saved: ₹${totalSaved.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () => showSavingForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add New Saving'),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: savings.isEmpty
                  ? const Center(child: Text("No savings yet. Add one!"))
                  : ListView.builder(
                itemCount: savings.length,
                itemBuilder: (context, index) {
                  final saving = savings[index];
                  final progress = (saving.currentAmount / saving.targetAmount).clamp(0.0, 1.0);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: _categoryIcon(saving.category),
                      title: Text(saving.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${saving.currentAmount.toStringAsFixed(0)} / ₹${saving.targetAmount.toStringAsFixed(0)}',
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.grey[300],
                            color: progress < 0.5
                                ? Colors.red
                                : progress < 0.8
                                ? Colors.orange
                                : Colors.green,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Matures on: ${saving.endDate.toLocal().toString().split(' ')[0]}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => showSavingForm(existing: saving),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteSaving(saving.id),
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
      ),
    );
  }

  Widget _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'lic':
        return const Icon(Icons.policy, color: Colors.indigo);
      case 'chit fund':
        return const Icon(Icons.savings, color: Colors.teal);
      case 'fixed deposit':
        return const Icon(Icons.lock, color: Colors.orange);
      case 'post bank':
        return const Icon(Icons.account_balance, color: Colors.green);
      default:
        return const Icon(Icons.wallet, color: Colors.grey);
    }
  }
}
