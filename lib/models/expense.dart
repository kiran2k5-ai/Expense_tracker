class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  // Factory constructor to create Expense from JSON
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['_id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      date: DateTime.parse(json['date']),
    );
  }

  // Convert Expense to JSON (useful if you ever need to send it)
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
    };
  }
}
