import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../providers/app_state.dart';
import '../helpers/helpers.dart';
import 'transaction_detail_screen.dart';
import 'package:provider/provider.dart';

class TransactionsScreen extends StatefulWidget {
  final String? filterClientId;
  const TransactionsScreen({super.key, this.filterClientId});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _statusFilter = 'All';
  final _statuses = ['All', 'Unpaid', 'Partially Paid', 'Fully Paid', 'Overdue'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    var txns = widget.filterClientId != null
        ? state.getClientTransactions(widget.filterClientId!)
        : [...state.transactions]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Apply status filter
    if (_statusFilter != 'All') {
      txns = txns.where((t) {
        switch (_statusFilter) {
          case 'Unpaid':
            return t.status == PaymentStatus.unpaid;
          case 'Partially Paid':
            return t.status == PaymentStatus.partiallyPaid;
          case 'Fully Paid':
            return t.status == PaymentStatus.fullyPaid;
          case 'Overdue':
            return t.isOverdue;
          default:
            return true;
        }
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _statuses.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_statuses[i]),
                  selected: _statusFilter == _statuses[i],
                  onSelected: (_) =>
                      setState(() => _statusFilter = _statuses[i]),
                ),
              ),
            ),
          ),
          Expanded(
            child: txns.isEmpty
                ? const Center(child: Text('No transactions found.'))
                : ListView.builder(
                    itemCount: txns.length,
                    itemBuilder: (ctx, i) {
                      final txn = txns[i];
                      final client = state.getClient(txn.clientId);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                statusColor(txn.status).withOpacity(0.15),
                            child: Icon(Icons.receipt,
                                color: statusColor(txn.status), size: 20),
                          ),
                          title: Text(client?.name ?? 'Unknown Client'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Total: ${formatCurrency(txn.totalAmount)} · Balance: ${formatCurrency(txn.remainingBalance)}'),
                              Text('Due: ${formatDate(txn.dueDate)}',
                                  style: TextStyle(
                                      color: txn.isOverdue
                                          ? Colors.red
                                          : Colors.grey.shade600,
                                      fontSize: 12)),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor(txn.status)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(txn.statusLabel,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: statusColor(txn.status),
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionDetailScreen(
                                  transactionId: txn.id,
                                  clientId: txn.clientId),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}