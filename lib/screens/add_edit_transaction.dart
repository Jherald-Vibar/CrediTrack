import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../providers/app_state.dart';
import '../helpers/helpers.dart';
import 'package:provider/provider.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final String clientId;
  final CreditTransaction? transaction;
  
  const AddEditTransactionScreen({
    super.key, 
    required this.clientId, 
    this.transaction
  });

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
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
    _amountCtrl = TextEditingController(text: t != null ? t.amountBorrowed.toString() : '');
    _interestCtrl = TextEditingController(text: t != null ? t.interestRate.toString() : '0');
    _monthsCtrl = TextEditingController(text: t != null ? t.monthsToPay.toString() : '1');
    _notesCtrl = TextEditingController(text: t?.notes ?? '');
    
    if (t != null) {
      _dateBorrowed = t.dateBorrowed;
      _dueDate = t.dueDate;
      _totalAmount = t.totalAmount;
    } else {
      // Initial calculation for new transactions
      WidgetsBinding.instance.addPostFrameCallback((_) => _recalcTotal());
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
      _dueDate = DateTime(
        _dateBorrowed.year,
        _dateBorrowed.month + months,
        _dateBorrowed.day,
      );
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateBorrowed,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Theme.of(context).primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateBorrowed = picked;
        _recalcTotal();
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
        ? _totalAmount / (int.tryParse(_monthsCtrl.text) ?? 1) 
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Loan' : 'New Loan', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Loan Details'),
              _buildInputCard([
                _buildTextField(
                  controller: _amountCtrl,
                  label: 'Principal Amount',
                  prefix: '₱',
                  icon: Icons.account_balance_wallet_outlined,
                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _interestCtrl,
                        label: 'Interest %',
                        suffix: '%/mo',
                        icon: Icons.percent_rounded,
                        keyboard: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _monthsCtrl,
                        label: 'Terms',
                        suffix: 'Mos',
                        icon: Icons.calendar_month_outlined,
                        keyboard: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ]),
              
              const SizedBox(height: 24),
              _buildSectionHeader('Schedule & Notes'),
              _buildInputCard([
                _buildDatePickerTile(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _notesCtrl,
                  label: 'Remarks/Notes',
                  icon: Icons.description_outlined,
                  maxLines: 2,
                ),
              ]),

              const SizedBox(height: 32),
              if (_totalAmount > 0) _buildSummaryCard(monthly),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _saving 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isEdit ? 'Update Loan Record' : 'Create Loan Record', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI BUILDING BLOCKS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildInputCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? prefix,
    String? suffix,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      onChanged: (_) => _recalcTotal(),
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal, fontSize: 13),
        prefixText: prefix,
        suffixText: suffix,
        prefixIcon: Icon(icon, size: 20, color: Colors.blueGrey),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildDatePickerTile() {
    return InkWell(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.blueGrey),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Start Date', style: TextStyle(color: Colors.grey, fontSize: 11)),
                Text(formatDate(_dateBorrowed), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double monthly) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade700]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Repayment', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text(formatCurrency(_totalAmount), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem('Monthly', formatCurrency(monthly)),
              _summaryItem('Due Date', formatDate(_dueDate)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}