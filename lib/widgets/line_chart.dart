import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';

class LineChartWidget extends StatelessWidget {
  final List<Expense> expenses;
  const LineChartWidget({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    // Group by day
    final Map<String, double> dailyTotals = {};

    for (var expense in expenses) {
      final day = DateFormat('dd MMM').format(expense.date); // e.g., 29 Jul
      dailyTotals[day] = (dailyTotals[day] ?? 0) + expense.amount;
    }

    final labels = dailyTotals.keys.toList();
    final values = dailyTotals.values.toList();

    final List<FlSpot> spots = [];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: Colors.indigoAccent,
              barWidth: 3,
              spots: spots,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.indigoAccent.withOpacity(0.3),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: _getYInterval(values),
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text('₹${value.toInt()}',
                        style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    return Transform.rotate(
                      angle: -0.5, // Slight tilt to avoid overlap
                      child: Text(
                        labels[index],
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true),
        ),
      ),
    );
  }

  double _getYInterval(List<double> values) {
    final max = values.reduce((a, b) => a > b ? a : b);
    final interval = (max / 4).ceilToDouble();
    return interval < 1 ? 1 : interval;
  }
}
