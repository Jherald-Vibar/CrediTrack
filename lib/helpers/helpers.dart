import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';

final currencyFmt = NumberFormat('₱#,##0.00', 'en_PH');
final dateFmt = DateFormat('MMM dd, yyyy');
final shortDateFmt = DateFormat('MM/dd/yy');

String formatCurrency(double amount) => currencyFmt.format(amount);
String formatDate(DateTime date) => dateFmt.format(date);

Color statusColor(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.unpaid:
      return Colors.red.shade600;
    case PaymentStatus.partiallyPaid:
      return Colors.orange.shade700;
    case PaymentStatus.fullyPaid:
      return Colors.green.shade700;
  }
}

double calculateTotalAmount(
    double principal, double interestRate, int months) {
  // Simple interest: I = P * r * t
  final interest = principal * (interestRate / 100) * (months / 12);
  return principal + interest;
}

double monthlyInstallment(double totalAmount, int months) =>
    months > 0 ? totalAmount / months : totalAmount;