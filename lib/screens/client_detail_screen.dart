import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
    if (client == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Client')),
          body: const Center(child: Text('Client not found.')));
    }

    final txns = state.getClientTransactions(clientId);
    final totalOwed = txns.fold(
        0.0,
        (s, t) =>
            s + (t.status != PaymentStatus.fullyPaid ? t.remainingBalance : 0));

    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddEditClientScreen(client: client)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, state, client),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Credit'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AddEditTransactionScreen(clientId: clientId)),
        ),
      ),
      body: ListView(
        children: [
          // ── Profile header ───────────────────────────────────────────────
          Container(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundImage: client.profileImagePath != null
                      ? FileImage(File(client.profileImagePath!))
                          as ImageProvider
                      : null,
                  child: client.profileImagePath == null
                      ? Text(client.name[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 30, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(height: 10),
                Text(client.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(client.contactNumber,
                      style: TextStyle(color: Colors.grey.shade700)),
                ]),
                const SizedBox(height: 2),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Flexible(
                      child: Text(client.address,
                          style: TextStyle(color: Colors.grey.shade700))),
                ]),
                const SizedBox(height: 12),
                Text(
                  'Total Outstanding: ${formatCurrency(totalOwed)}',
                  style: TextStyle(
                      color: totalOwed > 0
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ],
            ),
          ),

          // ── Transactions ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Credit Transactions',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (txns.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No transactions yet.')),
            )
          else
            ...txns.map((txn) => _TxnCard(client: client, txn: txn)),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AppState state, Client client) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Client?'),
        content: Text(
            'This will also delete all transactions for ${client.name}. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor(txn.status).withOpacity(0.15),
          child: Icon(Icons.receipt, color: statusColor(txn.status), size: 20),
        ),
        title: Text(
            '${formatCurrency(txn.amountBorrowed)} borrowed on ${formatDate(txn.dateBorrowed)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Balance: ${formatCurrency(txn.remainingBalance)} · Due: ${formatDate(txn.dueDate)}'),
            Row(children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor(txn.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(txn.statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: statusColor(txn.status),
                        fontWeight: FontWeight.bold)),
              ),
              if (txn.isOverdue) ...[
                const SizedBox(width: 6),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('OVERDUE',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ]),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.sms, size: 20),
              tooltip: 'Send SMS Reminder',
              onPressed: () async {
                final sent = await SmsService.sendReminder(
                    client: client, transaction: txn);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(sent
                      ? 'SMS app opened for ${client.name}'
                      : 'Could not open SMS app'),
                ));
              },
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(
                  transactionId: txn.id, clientId: client.id)),
        ),
      ),
    );
  }
}