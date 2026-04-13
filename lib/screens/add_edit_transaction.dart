import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../providers/app_state.dart';
import '../helpers/helpers.dart';
import 'package:provider/provider.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final String clientId;
  final CreditTransaction? transaction;
  const AddEditTransactionScreen(
      {super.key, required this.clientId, this.transaction});

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;
  late TextEditingController _interestCtrl;
  late TextEditingController _monthsCtrl;
  late TextEditingController _notesCtrl;
  DateTime _dateBorrowed = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  double _totalAmount = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _amountCtrl =
        TextEditingController(text: t != null ? t.amountBorrowed.toString() : '');
    _interestCtrl =
        TextEditingController(text: t != null ? t.interestRate.toString() : '0');
    _monthsCtrl =
        TextEditingController(text: t != null ? t.monthsToPay.toString() : '1');
    _notesCtrl = TextEditingController(text: t?.notes ?? '');
    if (t != null) {
      _dateBorrowed = t.dateBorrowed;
      _dueDate = t.dueDate;
      _totalAmount = t.totalAmount;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _interestCtrl.dispose();
    _monthsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _recalcTotal() {
    final principal = double.tryParse(_amountCtrl.text) ?? 0;
    final rate = double.tryParse(_interestCtrl.text) ?? 0;
    final months = int.tryParse(_monthsCtrl.text) ?? 1;
    setState(() {
      _totalAmount = calculateTotalAmount(principal, rate, months);
    });
  }

  Future<void> _pickDate(bool isBorrowed) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isBorrowed ? _dateBorrowed : _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isBorrowed) {
          _dateBorrowed = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    final principal = double.parse(_amountCtrl.text);
    final rate = double.parse(_interestCtrl.text);
    final months = int.parse(_monthsCtrl.text);
    _recalcTotal();

    if (widget.transaction == null) {
      await state.addTransaction(
        clientId: widget.clientId,
        amountBorrowed: principal,
        dateBorrowed: _dateBorrowed,
        dueDate: _dueDate,
        interestRate: rate,
        monthsToPay: months,
        totalAmount: _totalAmount,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    } else {
      final updated = CreditTransaction(
        id: widget.transaction!.id,
        clientId: widget.transaction!.clientId,
        amountBorrowed: principal,
        dateBorrowed: _dateBorrowed,
        dueDate: _dueDate,
        interestRate: rate,
        monthsToPay: months,
        totalAmount: _totalAmount,
        payments: widget.transaction!.payments,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        status: widget.transaction!.status,
        createdAt: widget.transaction!.createdAt,
      );
      updated.updateStatus();
      await state.updateTransaction(updated);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transaction != null;
    final monthly = _totalAmount > 0
        ? monthlyInstallment(_totalAmount, int.tryParse(_monthsCtrl.text) ?? 1)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Credit' : 'Add Credit'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Amount Borrowed (₱) *',
                prefixIcon: Icon(Icons.money),
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _recalcTotal(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null || double.parse(v) <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _interestCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Interest Rate (%)',
                    prefixIcon: Icon(Icons.percent),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _recalcTotal(),
                  validator: (v) {
                    if (v == null) return null;
                    final d = double.tryParse(v);
                    if (d == null || d < 0) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _monthsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Months to Pay',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _recalcTotal(),
                  validator: (v) {
                    if (v == null) return null;
                    final i = int.tryParse(v);
                    if (i == null || i < 1) return 'Min 1';
                    return null;
                  },
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // Date pickers
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text('Borrowed: ${formatDate(_dateBorrowed)}'),
                  onPressed: () => _pickDate(true),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event_busy),
                  label: Text('Due: ${formatDate(_dueDate)}'),
                  onPressed: () => _pickDate(false),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(14)),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Computed summary
            if (_totalAmount > 0)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Summary',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _Row('Principal', formatCurrency(double.tryParse(_amountCtrl.text) ?? 0)),
                    _Row(
                        'Interest',
                        formatCurrency(_totalAmount -
                            (double.tryParse(_amountCtrl.text) ?? 0))),
                    const Divider(),
                    _Row('Total Amount', formatCurrency(_totalAmount),
                        bold: true),
                    _Row('Monthly Installment', formatCurrency(monthly)),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isEdit ? 'Save Changes' : 'Add Credit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.bold)
        : const TextStyle();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}