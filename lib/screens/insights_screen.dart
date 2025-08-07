import 'package:flutter/material.dart';
import '../models/expense.dart';

class InsightsScreen extends StatelessWidget {
  final List<Expense> expenses;

  const InsightsScreen({super.key, required this.expenses});

  String getOverBudgetCategory() {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final foodTotal = expenses
        .where((e) =>
    e.category.toLowerCase() == 'food' && e.date.isAfter(oneWeekAgo))
        .fold(0.0, (sum, e) => sum + e.amount);
    const foodBudget = 1000.0;

    if (foodTotal > foodBudget) {
      final overPercent =
      ((foodTotal - foodBudget) / foodBudget * 100).round();
      return "You're $overPercent% over your Food budget this week";
    }

    return "Food budget is within limits";
  }

  String getTransportTrend() {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    double thisWeek = expenses
        .where((e) =>
    e.category.toLowerCase() == 'transport' &&
        e.date.isAfter(thisWeekStart))
        .fold(0.0, (sum, e) => sum + e.amount);

    double lastWeek = expenses
        .where((e) =>
    e.category.toLowerCase() == 'transport' &&
        e.date.isAfter(lastWeekStart) &&
        e.date.isBefore(thisWeekStart))
        .fold(0.0, (sum, e) => sum + e.amount);

    if (lastWeek == 0) return "No transport data from last week";

    final drop = ((lastWeek - thisWeek) / lastWeek * 100).round();
    return drop > 0
        ? "📉 Transport spending down $drop%"
        : "No drop in transport spend";
  }

  String getSpendPrediction() {
    if (expenses.isEmpty) return "Not enough data to predict";

    final now = DateTime.now();
    final thisMonth = expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .toList();

    if (thisMonth.isEmpty) return "Not enough data to predict";

    double total = thisMonth.fold(0.0, (sum, e) => sum + e.amount);
    int days = now.day;

    final dailyAvg = total / days;
    final predicted = (dailyAvg * 30).round();

    return "Next Month Prediction: ₹$predicted spend";
  }

  String getLoggingStreak() {
    final now = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: i));
      final logged = expenses.any((e) =>
      e.date.day == day.day &&
          e.date.month == day.month &&
          e.date.year == day.year);
      if (logged) {
        streak++;
      } else {
        break;
      }
    }

    if (streak >= 30) return "🎯 30-Day Logging Streak Achieved!";
    if (streak >= 14) return "🏆 14-Day Logging Streak!";
    if (streak >= 7) return "🎖️ 7-Day Logging Streak!";
    return "Keep logging to build a streak!";
  }

  List<String> getNeglectedCategories() {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final recentExpenses =
    expenses.where((e) => e.date.isAfter(oneWeekAgo)).toList();

    final allCategories =
    expenses.map((e) => e.category.toLowerCase()).toSet().toList();

    final usedRecently = recentExpenses
        .map((e) => e.category.toLowerCase())
        .toSet()
        .toList();

    return allCategories
        .where((cat) => !usedRecently.contains(cat))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final neglected = getNeglectedCategories();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 Smart Insights',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          InsightCard(
            icon: Icons.warning,
            title: getOverBudgetCategory(),
            color: Colors.orange[100]!,
          ),
          InsightCard(
            icon: Icons.trending_down,
            title: getTransportTrend(),
            color: Colors.green[100]!,
          ),
          const SizedBox(height: 24),
          Text('🔮 Predictions',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          InsightCard(
            icon: Icons.show_chart,
            title: getSpendPrediction(),
            color: Colors.blue[100]!,
          ),
          const SizedBox(height: 24),
          Text('🏅 Gamification',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          InsightCard(
            icon: Icons.emoji_events,
            title: getLoggingStreak(),
            color: Colors.purple[100]!,
          ),
          if (neglected.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('⚠️ Neglected Categories',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...neglected.map((cat) => InsightCard(
              icon: Icons.info,
              title: "No spending in '$cat' last 7 days",
              color: Colors.red[100]!,
            )),
          ]
        ],
      ),
    );
  }
}

class InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const InsightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title),
      ),
    );
  }
}
