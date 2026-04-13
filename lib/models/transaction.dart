import 'payment.dart';

enum PaymentStatus { unpaid, partiallyPaid, fullyPaid }

class CreditTransaction {
  final String id;
  final String clientId;
  double amountBorrowed;
  DateTime dateBorrowed;
  DateTime dueDate;
  double interestRate; // percentage
  int monthsToPay;
  double totalAmount; // amountBorrowed + interest
  List<Payment> payments;
  String? notes;
  PaymentStatus status;
  DateTime createdAt;
  bool reminderSent;

  CreditTransaction({
    required this.id,
    required this.clientId,
    required this.amountBorrowed,
    required this.dateBorrowed,
    required this.dueDate,
    required this.interestRate,
    required this.monthsToPay,
    required this.totalAmount,
    List<Payment>? payments,
    this.notes,
    PaymentStatus? status,
    DateTime? createdAt,
    this.reminderSent = false,
  })  : payments = payments ?? [],
        status = status ?? PaymentStatus.unpaid,
        createdAt = createdAt ?? DateTime.now();

  double get totalPaid =>
      payments.fold(0.0, (sum, p) => sum + p.amount);

  double get remainingBalance => totalAmount - totalPaid;

  bool get isOverdue =>
      dueDate.isBefore(DateTime.now()) && status != PaymentStatus.fullyPaid;

  void updateStatus() {
    if (totalPaid <= 0) {
      status = PaymentStatus.unpaid;
    } else if (totalPaid >= totalAmount) {
      status = PaymentStatus.fullyPaid;
    } else {
      status = PaymentStatus.partiallyPaid;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'amountBorrowed': amountBorrowed,
        'dateBorrowed': dateBorrowed.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'interestRate': interestRate,
        'monthsToPay': monthsToPay,
        'totalAmount': totalAmount,
        'payments': payments.map((p) => p.toJson()).toList(),
        'notes': notes,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'reminderSent': reminderSent,
      };

  factory CreditTransaction.fromJson(Map<String, dynamic> json) =>
      CreditTransaction(
        id: json['id'],
        clientId: json['clientId'],
        amountBorrowed: (json['amountBorrowed'] as num).toDouble(),
        dateBorrowed: DateTime.parse(json['dateBorrowed']),
        dueDate: DateTime.parse(json['dueDate']),
        interestRate: (json['interestRate'] as num).toDouble(),
        monthsToPay: json['monthsToPay'],
        totalAmount: (json['totalAmount'] as num).toDouble(),
        payments: (json['payments'] as List<dynamic>?)
                ?.map((p) => Payment.fromJson(p))
                .toList() ??
            [],
        notes: json['notes'],
        status: PaymentStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => PaymentStatus.unpaid,
        ),
        createdAt: DateTime.parse(json['createdAt']),
        reminderSent: json['reminderSent'] ?? false,
      );

  String get statusLabel {
    switch (status) {
      case PaymentStatus.unpaid:
        return 'Unpaid';
      case PaymentStatus.partiallyPaid:
        return 'Partially Paid';
      case PaymentStatus.fullyPaid:
        return 'Fully Paid';
    }
  }
}