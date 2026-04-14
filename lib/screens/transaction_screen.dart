import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);

    var txns = widget.filterClientId != null
        ? state.getClientTransactions(widget.filterClientId!)
        : [...state.transactions]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (_statusFilter != 'All') {
      txns = txns.where((t) {
        switch (_statusFilter) {
          case 'Unpaid': return t.status == PaymentStatus.unpaid;
          case 'Partially Paid': return t.status == PaymentStatus.partiallyPaid;
          case 'Fully Paid': return t.status == PaymentStatus.fullyPaid;
          case 'Overdue': return t.isOverdue;
          default: return true;
        }
      }).toList();
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Transaction Ledger'),
        centerTitle: false,
        backgroundColor: theme.colorScheme.surface,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // --- Modern Filter Chips ---
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statuses.length,
              itemBuilder: (ctx, i) {
                final isSelected = _statusFilter == _statuses[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_statuses[i]),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _statusFilter = _statuses[i]),
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    showCheckmark: false,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: txns.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: txns.length + 1, // Space for floating nav
                    itemBuilder: (ctx, i) {
                      if (i == txns.length) return const SizedBox(height: 100);
                      
                      final txn = txns[i];
                      final client = state.getClient(txn.clientId);
                      return _ModernTransactionCard(txn: txn, clientName: client?.name ?? 'Unknown');
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No transactions found', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _ModernTransactionCard extends StatelessWidget {
  final CreditTransaction txn;
  final String clientName;

  const _ModernTransactionCard({required this.txn, required this.clientName});

  @override
  Widget build(BuildContext context) {
    final statusCol = statusColor(txn.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(
              transactionId: txn.id,
              clientId: txn.clientId,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon with status background
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusCol.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  txn.isOverdue ? Icons.priority_high_rounded : Icons.receipt_rounded,
                  color: statusCol,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Client & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due ${formatDate(txn.dueDate)}',
                      style: TextStyle(
                        color: txn.isOverdue ? Colors.red.shade700 : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: txn.isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(txn.remainingBalance),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: txn.remainingBalance > 0 ? Colors.black87 : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusCol.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      txn.statusLabel.toUpperCase(),
                      style: TextStyle(
                        color: statusCol,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
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
}