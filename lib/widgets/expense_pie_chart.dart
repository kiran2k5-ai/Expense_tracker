import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';

class ExpensePieChart extends StatelessWidget {
  final List<Expense> expenses;

  const ExpensePieChart({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> categoryTotals = {};
    for (var exp in expenses) {
      categoryTotals.update(exp.category, (val) => val + exp.amount,
          ifAbsent: () => exp.amount);
    }

    final total = categoryTotals.values.fold(0.0, (sum, item) => sum + item);
    final keys = categoryTotals.keys.toList();
    final values = categoryTotals.values.toList();

    if (total == 0) {
      return const Center(child: Text("No data to display"));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        
        return Container(
          height: isSmallScreen ? 300 : 250,
          padding: const EdgeInsets.all(8),
          child: isSmallScreen 
            ? Column(
                children: [
                  // Pie Chart Section for mobile
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: List.generate(categoryTotals.length, (index) {
                          final value = values[index];
                          return PieChartSectionData(
                            value: value,
                            title: '',
                            color: Colors.primaries[index % Colors.primaries.length],
                            radius: isSmallScreen ? 45 : 60,
                          );
                        }),
                        centerSpaceRadius: isSmallScreen ? 20 : 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Legend Section for mobile
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryTotals.length,
                      itemBuilder: (context, index) {
                        final category = keys[index];
                        final value = values[index];
                        final percent = (value / total * 100).toStringAsFixed(1);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.primaries[index % Colors.primaries.length],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                category,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '$percent%',
                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  // Pie Chart Section for desktop
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: List.generate(categoryTotals.length, (index) {
                          final value = values[index];
                          return PieChartSectionData(
                            value: value,
                            title: '',
                            color: Colors.primaries[index % Colors.primaries.length],
                            radius: 60,
                          );
                        }),
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  // Legend Section for desktop
                  Expanded(
                    flex: 2,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: categoryTotals.length,
                      itemBuilder: (context, index) {
                        final category = keys[index];
                        final value = values[index];
                        final percent = (value / total * 100).toStringAsFixed(1);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.primaries[index % Colors.primaries.length],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$category - $percent%',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
        );
      },
    );
  }
}
