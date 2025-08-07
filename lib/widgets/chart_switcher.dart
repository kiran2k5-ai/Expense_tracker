import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'expense_pie_chart.dart';
import 'monthly_bar_chart.dart';
import 'line_chart.dart';

class ChartSwitcher extends StatefulWidget {
  final List<Expense> expenses;

  const ChartSwitcher({super.key, required this.expenses});

  @override
  State<ChartSwitcher> createState() => _ChartSwitcherState();
}

class _ChartSwitcherState extends State<ChartSwitcher> {
  String selectedChart = 'Pie';
  String selectedFilter = 'This Month';

  List<String> filters = ['This Week', 'This Month', 'This Year'];

  List<Expense> get filteredExpenses {
    final now = DateTime.now();
    return widget.expenses.where((expense) {
      if (selectedFilter == 'This Week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return expense.date.isAfter(startOfWeek);
      } else if (selectedFilter == 'This Month') {
        return expense.date.month == now.month && expense.date.year == now.year;
      } else if (selectedFilter == 'This Year') {
        return expense.date.year == now.year;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Widget currentChart;
    if (selectedChart == 'Pie') {
      currentChart = ExpensePieChart(expenses: filteredExpenses);
    } else if (selectedChart == 'Bar') {
      currentChart = MonthlyBarChart(expenses: filteredExpenses);
    } else {
      currentChart = LineChartWidget(expenses: filteredExpenses);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Spending Overview",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

        const SizedBox(height: 12),

        // 👇 Filter Dropdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DropdownButton<String>(
              value: selectedFilter,
              items: filters
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedFilter = val!;
                });
              },
            ),
            Row(
              children: ['Pie', 'Bar', 'Line'].map((type) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: selectedChart == type,
                    onSelected: (_) {
                      setState(() => selectedChart = type);
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        const SizedBox(height: 16),
        currentChart,
      ],
    );
  }
}
