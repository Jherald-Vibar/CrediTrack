import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../models/payment.dart';
import '../providers/app_state.dart';
import '../services/sms_service.dart';
import '../helpers/helpers.dart';
import 'package:creditrack/screens/add_edit_transaction.dart';
import 'package:provider/provider.dart';

class TransactionDetailScreen extends StatelessWidget {
  final String transactionId;
  final String clientId;
  const TransactionDetailScreen(
      {super.key, required this.transactionId, required this.clientId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final txn = state.getTransaction(transactionId);
    final client = state.getClient(clientId);

    if (txn == null || client == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Transaction')),
          body: const Center(child: Text('Not found.')));
    }

    final pct = txn.totalAmount > 0 ? (txn.totalPaid / txn.totalAmount).clamp(0.0, 1.0) : 0.0;
    final monthly = monthlyInstallment(txn.totalAmount, txn.monthsToPay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditTransactionScreen(
                    clientId: clientId, transaction: txn),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, state, txn),
          ),
        ],
      ),
      floatingActionButton: txn.status != PaymentStatus.fullyPaid
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.payment),
              label: const Text('Add Payment'),
              onPressed: () => _showAddPaymentDialog(context, state, txn),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status card ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor(txn.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor(txn.status).withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(txn.statusLabel,
                        style: TextStyle(
                            color: statusColor(txn.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    if (txn.isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('OVERDUE',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.grey.shade300,
                  color: statusColor(txn.status),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text('${(pct * 100).toStringAsFixed(1)}% paid',
                    style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Credit details ────────────────────────────────────────────
          _Section('Credit Details', [
            _InfoRow('Client', client.name),
            _InfoRow('Amount Borrowed', formatCurrency(txn.amountBorrowed)),
            _InfoRow('Interest Rate', '${txn.interestRate}%'),
            _InfoRow('Months to Pay', '${txn.monthsToPay} month(s)'),
            _InfoRow('Total Amount', formatCurrency(txn.totalAmount),
                highlight: true),
            _InfoRow('Monthly Installment', formatCurrency(monthly)),
            _InfoRow('Date Borrowed', formatDate(txn.dateBorrowed)),
            _InfoRow('Due Date', formatDate(txn.dueDate)),
            if (txn.notes != null && txn.notes!.isNotEmpty)
              _InfoRow('Notes', txn.notes!),
          ]),
          const SizedBox(height: 16),

          // ── Payment summary ───────────────────────────────────────────
          _Section('Payment Summary', [
            _InfoRow('Total Amount Due', formatCurrency(txn.totalAmount)),
            _InfoRow('Total Paid', formatCurrency(txn.totalPaid),
                color: Colors.green.shade700),
            _InfoRow('Remaining Balance', formatCurrency(txn.remainingBalance),
                color: txn.remainingBalance > 0
                    ? Colors.red.shade700
                    : Colors.green.shade700,
                highlight: true),
          ]),
          const SizedBox(height: 16),

          // ── SMS Reminder ──────────────────────────────────────────────
          OutlinedButton.icon(
            icon: const Icon(Icons.sms),
            label: const Text('Send SMS Reminder'),
            onPressed: () async {
              final sent = await SmsService.sendReminder(
                  client: client, transaction: txn);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    sent ? 'SMS app opened!' : 'Could not open SMS app'),
              ));
            },
          ),
          const SizedBox(height: 16),

          // ── Payment History ───────────────────────────────────────────
          Text('Payment History',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (txn.payments.isEmpty)
            const Text('No payments recorded yet.',
                style: TextStyle(color: Colors.grey))
          else
            ...txn.payments
                .sorted()
                .map((p) => _PaymentTile(payment: p,
                    onDelete: () => _deletePayment(context, state, txn, p))),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _showAddPaymentDialog(
      BuildContext context, AppState state, CreditTransaction txn) async {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime datePaid = DateTime.now();
    PaymentMethod method = PaymentMethod.cash;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Payment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                decoration: InputDecoration(
                  labelText: 'Payment Amount (₱) — Balance: ${formatCurrency(txn.remainingBalance)}',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.money),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentMethod>(
                value: method,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                items: PaymentMethod.values
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(_methodLabel(m)),
                        ))
                    .toList(),
                onChanged: (v) => setSt(() => method = v!),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text('Date: ${formatDate(datePaid)}'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: datePaid,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setSt(() => datePaid = picked);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Enter a valid payment amount')));
                      return;
                    }
                    await state.addPayment(
                      transactionId: txn.id,
                      amount: amount,
                      datePaid: datePaid,
                      method: method,
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Record Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePayment(BuildContext context, AppState state,
      CreditTransaction txn, Payment payment) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Payment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final updated = CreditTransaction(
        id: txn.id,
        clientId: txn.clientId,
        amountBorrowed: txn.amountBorrowed,
        dateBorrowed: txn.dateBorrowed,
        dueDate: txn.dueDate,
        interestRate: txn.interestRate,
        monthsToPay: txn.monthsToPay,
        totalAmount: txn.totalAmount,
        payments: txn.payments.where((p) => p.id != payment.id).toList(),
        notes: txn.notes,
        status: txn.status,
        createdAt: txn.createdAt,
      );
      updated.updateStatus();
      await state.updateTransaction(updated);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState state, CreditTransaction txn) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('All payment history will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await state.deleteTransaction(txn.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  String _methodLabel(PaymentMethod m) {
    switch (m) {
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

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  final VoidCallback onDelete;
  const _PaymentTile({required this.payment, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(Icons.check, color: Colors.green.shade700, size: 18),
        ),
        title: Text(formatCurrency(payment.amount),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${formatDate(payment.datePaid)} · ${payment.methodLabel}'
            '${payment.notes != null ? ' · ${payment.notes}' : ''}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool highlight;
  const _InfoRow(this.label, this.value,
      {this.color, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight:
                  highlight ? FontWeight.bold : FontWeight.w500,
              color: color,
              fontSize: highlight ? 15 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

extension _SortedPayments on List<Payment> {
  List<Payment> sorted() =>
      [...this]..sort((a, b) => b.datePaid.compareTo(a.datePaid));
}