import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<Expense> expenses;

  const MonthlyBarChart({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> dayTotals = {};

    for (var expense in expenses) {
      final weekday = DateFormat('EEE').format(expense.date); // e.g., Mon
      dayTotals[weekday] = (dayTotals[weekday] ?? 0) + expense.amount;
    }

    final dayOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final barGroups = <BarChartGroupData>[];
    int x = 0;

    for (final day in dayOrder) {
      final total = dayTotals[day] ?? 0;
      barGroups.add(
        BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(
              toY: total,
              width: 35,
              borderRadius: BorderRadius.circular(4),
              color: Colors.teal.shade300,
            ),
          ],
        ),
      );
      x++;
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: _getYInterval(dayTotals.values.toList()),
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text('₹${value.toInt()}',
                        style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < dayOrder.length) {
                    return Text(
                      dayOrder[index],
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getYInterval(List<double> values) {
    if (values.isEmpty) return 100;
    final max = values.reduce((a, b) => a > b ? a : b);
    final interval = (max / 4).ceilToDouble();
    return interval < 1 ? 1 : interval;
  }
}
