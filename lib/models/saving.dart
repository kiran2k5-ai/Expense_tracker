class Saving {
  final String id;
  final String category;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime startDate;
  final DateTime endDate;

  Saving({
    required this.id,
    required this.category,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.startDate,
    required this.endDate,
  });

  factory Saving.fromJson(Map<String, dynamic> json) {
    return Saving(
      id: json['_id'],
      category: json['category'],
      name: json['name'],
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}
