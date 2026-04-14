import 'dart:io';
import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/transaction.dart';
import '../providers/app_state.dart';
import '../services/sms_service.dart';
import '../helpers/helpers.dart';
import 'add_edit_client_screen.dart';
import 'package:creditrack/screens/add_edit_transaction.dart';
import 'transaction_detail_screen.dart';
import 'package:provider/provider.dart';

class ClientDetailScreen extends StatelessWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final client = state.getClient(clientId);
    final theme = Theme.of(context);

    if (client == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Client')),
          body: const Center(child: Text('Client not found.')));
    }

    final txns = state.getClientTransactions(clientId);
    final totalOwed = txns.fold(0.0, (s, t) => s + (t.status != PaymentStatus.fullyPaid ? t.remainingBalance : 0));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddEditClientScreen(client: client)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(context, state, client),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Credit', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddEditTransactionScreen(clientId: clientId)),
        ),
      ),
      body: Column(
        children: [
          // --- PREMUM HEADER SECTION ---
          _buildHeader(context, client, totalOwed),

          // --- TRANSACTIONS LIST ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Credit History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('${txns.length} records', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 16),
                if (txns.isEmpty)
                  _buildEmptyState()
                else
                  ...txns.map((txn) => _TxnCard(client: client, txn: txn)),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Client client, double totalOwed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 32),
      decoration: BoxDecoration(
        color: Colors.blue.shade900,
        image: DecorationImage(
          image: const NetworkImage('https://www.transparenttextures.com/patterns/carbon-fibre.png'),
          opacity: 0.1,
          repeat: ImageRepeat.repeat,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white24,
            child: CircleAvatar(
              radius: 41,
              backgroundColor: Colors.white,
              backgroundImage: client.profileImagePath != null ? FileImage(File(client.profileImagePath!)) : null,
              child: client.profileImagePath == null
                  ? Text(client.name[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold))
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(client.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          _iconText(Icons.phone_iphone_rounded, client.contactNumber),
          const SizedBox(height: 4),
          _iconText(Icons.location_on_rounded, client.address),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Outstanding Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text(formatCurrency(totalOwed),
                    style: TextStyle(
                        color: totalOwed > 0 ? Colors.orangeAccent : Colors.greenAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: Colors.white60),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No transactions yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state, Client client) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Client?'),
        content: Text('This will delete ${client.name} and all their debt history. This action is permanent.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Everything', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await state.deleteClient(client.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _TxnCard extends StatelessWidget {
  final Client client;
  final CreditTransaction txn;
  const _TxnCard({required this.client, required this.txn});

  @override
  Widget build(BuildContext context) {
    final bool overdue = txn.isOverdue && txn.status != PaymentStatus.fullyPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TransactionDetailScreen(transactionId: txn.id, clientId: client.id)),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: statusColor(txn.status).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.article_outlined, color: statusColor(txn.status), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatCurrency(txn.amountBorrowed), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Due: ${formatDate(txn.dueDate)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _badge(
                    overdue ? 'OVERDUE' : txn.statusLabel.toUpperCase(),
                    overdue ? Colors.red : statusColor(txn.status),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => SmsService.sendReminder(client: client, transaction: txn),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.sms_rounded, size: 18, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }
}