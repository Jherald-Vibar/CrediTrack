enum PaymentMethod { cash, gcash, bankTransfer, other }

class Payment {
  final String id;
  double amount;
  DateTime datePaid;
  PaymentMethod method;
  String? notes;

  Payment({
    required this.id,
    required this.amount,
    required this.datePaid,
    required this.method,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'datePaid': datePaid.toIso8601String(),
        'method': method.name,
        'notes': notes,
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'],
        amount: (json['amount'] as num).toDouble(),
        datePaid: DateTime.parse(json['datePaid']),
        method: PaymentMethod.values.firstWhere(
          (e) => e.name == json['method'],
          orElse: () => PaymentMethod.cash,
        ),
        notes: json['notes'],
      );

  String get methodLabel {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.gcash:
        return 'GCash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.other:
        return 'Other';
    }
  }
}