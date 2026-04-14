import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart'; 
import '../models/transaction.dart';
import '../models/payment.dart';
import '../models/client.dart';
import '../providers/app_state.dart';
import '../services/sms_service.dart';
import '../helpers/helpers.dart';
import 'package:creditrack/screens/add_edit_transaction.dart';
import 'package:provider/provider.dart';

class TransactionDetailScreen extends StatelessWidget {
  final String transactionId;
  final String clientId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    required this.clientId,
  });

  // --- YOUR BUSINESS DETAILS (Update these) ---
  final String myGcashNumber = "09123456789"; 
  final String myBankName = "BDO Unibank";
  final String myBankAccName = "JUAN DELA CRUZ";
  final String myBankAccNum = "001234567890";

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final txn = state.getTransaction(transactionId);
    final client = state.getClient(clientId);

    if (txn == null || client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction')),
        body: const Center(child: Text('Not found.')),
      );
    }

    final double progress = txn.totalAmount > 0
        ? (txn.totalPaid / txn.totalAmount).clamp(0.0, 1.0)
        : 0.0;
    
    final monthly = monthlyInstallment(txn.totalAmount, txn.monthsToPay);
    final totalInterest = txn.totalAmount - txn.amountBorrowed;
    final monthlyInterest = txn.monthsToPay > 0 ? totalInterest / txn.monthsToPay : totalInterest;
    final monthlyPrincipal = txn.monthsToPay > 0 ? txn.amountBorrowed / txn.monthsToPay : txn.amountBorrowed;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Credit Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditTransactionScreen(clientId: clientId, transaction: txn),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, state, txn),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(context, state, txn, client),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildHeroSection(theme, txn, client, progress),
            const SizedBox(height: 24),
            _buildSectionHeader('Loan Information'),
            _buildInfoCard([
              _InfoRow('Principal', formatCurrency(txn.amountBorrowed)),
              _InfoRow('Interest Rate', '${txn.interestRate}% / mo', color: Colors.orange.shade800),
              _InfoRow('Total to Pay', formatCurrency(txn.totalAmount), highlight: true),
              _InfoRow('Monthly Due', formatCurrency(monthly), valueColor: Colors.green.shade700),
              _InfoRow('Due Date', formatDate(txn.dueDate), valueColor: txn.isOverdue ? Colors.red : Colors.black87),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('Installment Breakdown'),
            _buildBreakdownTable(txn, monthlyPrincipal, monthlyInterest, monthly),
            const SizedBox(height: 24),
            _buildSectionHeader('Payment History'),
            if (txn.payments.isEmpty)
              _buildEmptyState()
            else
              ...txn.payments.sorted().map((p) => _PaymentTile(
                    payment: p,
                    onTap: () => _showReceiptDialog(context, p, txn, client),
                    onDelete: () => _deletePayment(context, state, txn, p),
                  )),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // --- UI SECTIONS ---

  Widget _buildHeroSection(ThemeData theme, CreditTransaction txn, Client client, double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Text(client.name[0], style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ),
          const SizedBox(height: 12),
          Text(client.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('CURRENT BALANCE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w800, letterSpacing: 1)),
          Text(formatCurrency(txn.remainingBalance),
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: -1)),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(progress * 100).toInt()}% Paid', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              _buildSmsAction(client, txn),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmsAction(Client client, CreditTransaction txn) {
    return InkWell(
      onTap: () => SmsService.sendReminder(client: client, transaction: txn),
      child: Row(
        children: [
          Icon(Icons.sms_outlined, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text('Send Reminder', style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(children: children),
    );
  }

  Widget _buildBreakdownTable(CreditTransaction txn, double principal, double interest, double total) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        children: [
          ...List.generate(txn.monthsToPay, (i) {
            final bool isPaid = txn.payments.length > i;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: Colors.grey.shade50))),
              child: Row(
                children: [
                  Text('Month ${i + 1}', style: TextStyle(fontSize: 13, color: isPaid ? Colors.green : Colors.black87, fontWeight: isPaid ? FontWeight.bold : FontWeight.normal)),
                  const Spacer(),
                  if (isPaid) const Icon(Icons.check_circle, size: 16, color: Colors.green)
                  else Text(formatCurrency(total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- THE MODERN PAYMENT MODAL ---

  Future<void> _showAddPaymentDialog(BuildContext context, AppState state, CreditTransaction txn, Client client) async {
    final monthly = monthlyInstallment(txn.totalAmount, txn.monthsToPay);
    final fixedAmount = monthly > txn.remainingBalance ? txn.remainingBalance : monthly;
    final notesCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    PaymentMethod method = PaymentMethod.cash;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          padding: EdgeInsets.only(left: 24, right: 24, top: 32, bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Record Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              // SELECTOR
              Row(
                children: [
                  _methodTab(isSelected: method == PaymentMethod.cash, label: 'Cash', icon: Icons.payments, onTap: () => setSt(() => method = PaymentMethod.cash)),
                  _methodTab(isSelected: method == PaymentMethod.gcash, label: 'GCash', icon: Icons.qr_code_2, onTap: () => setSt(() => method = PaymentMethod.gcash)),
                  _methodTab(isSelected: method == PaymentMethod.bankTransfer, label: 'Bank', icon: Icons.account_balance, onTap: () => setSt(() => method = PaymentMethod.bankTransfer)),
                ],
              ),
              const SizedBox(height: 24),

              // GCASH QR SECTION
              if (method == PaymentMethod.gcash) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.shade100)),
                  child: Column(
                    children: [
                      QrImageView(
                        data: "gcash://pay?number=$myGcashNumber",
                        version: QrVersions.auto,
                        size: 140.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(myGcashNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () => Clipboard.setData(ClipboardData(text: myGcashNumber))),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // BANK DETAILS SECTION
              if (method == PaymentMethod.bankTransfer) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(myBankName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      Text("Account: $myBankAccName"),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(myBankAccNum, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                          IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () => Clipboard.setData(ClipboardData(text: myBankAccNum))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // INPUT FIELDS (REF & RESTORED NOTES)
              if (method != PaymentMethod.cash) ...[
                TextField(
                  controller: refCtrl,
                  decoration: InputDecoration(
                    labelText: 'Reference Number',
                    prefixIcon: const Icon(Icons.tag),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Payment Notes',
                  hintText: 'e.g. Paid in full / partial',
                  prefixIcon: const Icon(Icons.note_add_outlined),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),

              ListTile(
                title: const Text('Amount Received'),
                trailing: Text(formatCurrency(fixedAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  String finalNotes = notesCtrl.text.trim();
                  if (refCtrl.text.isNotEmpty) {
                    finalNotes = "Ref: ${refCtrl.text}${finalNotes.isNotEmpty ? ' | $finalNotes' : ''}";
                  }
                  
                  await state.addPayment(
                    transactionId: txn.id, 
                    amount: fixedAmount, 
                    datePaid: DateTime.now(), 
                    method: method, 
                    notes: finalNotes.isEmpty ? null : finalNotes
                  );
                  
                  final updated = state.getTransaction(txn.id);
                  if (updated != null) {
                    // --- THANK YOU SMS LOGIC ---
                    final msg = "Thank you, ${client.name}! We received your payment of ${formatCurrency(fixedAmount)} via ${method.name.toUpperCase()}. Your remaining balance is ${formatCurrency(updated.remainingBalance)}.";
                    await SmsService.sendCustomSms(contact: client.contactNumber, message: msg);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Confirm & Send Thank You', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _methodTab({required bool isSelected, required String label, required IconData icon, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.black54, size: 20),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, AppState state, CreditTransaction txn, Client client) {
    if (txn.status == PaymentStatus.fullyPaid) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      color: Colors.white,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () => _showAddPaymentDialog(context, state, txn, client),
        child: const Text('Add Payment Record', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showReceiptDialog(BuildContext context, Payment p, CreditTransaction txn, Client client) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            const Text('Payment Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(height: 32),
            _receiptRow('Client', client.name),
            _receiptRow('Amount', formatCurrency(p.amount), bold: true),
            _receiptRow('Method', p.methodLabel),
            _receiptRow('Balance', formatCurrency(txn.remainingBalance), color: Colors.red),
            const SizedBox(height: 24),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  Future<void> _deletePayment(BuildContext context, AppState state, CreditTransaction txn, Payment payment) async {
    final ok = await _confirmAction(context, 'Delete Payment?', 'This will undo the payment.');
    if (ok == true) {
      final updated = CreditTransaction(
        id: txn.id, clientId: txn.clientId, amountBorrowed: txn.amountBorrowed, dateBorrowed: txn.dateBorrowed,
        dueDate: txn.dueDate, interestRate: txn.interestRate, monthsToPay: txn.monthsToPay, totalAmount: txn.totalAmount,
        payments: txn.payments.where((p) => p.id != payment.id).toList(), notes: txn.notes, status: txn.status, createdAt: txn.createdAt,
      );
      updated.updateStatus();
      await state.updateTransaction(updated);
    }
  }

  Future<void> _confirmDelete(BuildContext context, AppState state, CreditTransaction txn) async {
    final ok = await _confirmAction(context, 'Delete Loan?', 'All history will be lost.');
    if (ok == true) {
      await state.deleteTransaction(txn.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<bool?> _confirmAction(BuildContext context, String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No payments yet.', style: TextStyle(color: Colors.grey))));
}

// --- SUB-WIDGETS ---

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _PaymentTile({required this.payment, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.receipt_long, color: Colors.blueGrey),
        title: Text(formatCurrency(payment.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('${formatDate(payment.datePaid)} • ${payment.methodLabel}', style: const TextStyle(fontSize: 11)),
        trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey), onPressed: onDelete),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final Color? valueColor;
  final bool highlight;
  const _InfoRow(this.label, this.value, {this.color, this.valueColor, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: highlight ? FontWeight.bold : FontWeight.w600, color: valueColor ?? Colors.black87, fontSize: 14)),
        ],
      ),
    );
  }
}

extension _SortedPayments on List<Payment> {
  List<Payment> sorted() => [...this]..sort((a, b) => b.datePaid.compareTo(a.datePaid));
}