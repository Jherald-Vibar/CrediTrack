import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/app_state.dart';
import '../helpers/helpers.dart';
import 'package:creditrack/screens/client_screen.dart';
import 'package:creditrack/screens/transaction_screen.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    final overdue = state.transactions.where((t) => t.isOverdue).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CrediTrack'),
        centerTitle: false,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: state.init,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Summary Cards ───────────────────────────────────────
                  Row(
                    children: [
                      _SummaryCard(
                        label: 'Total Receivables',
                        value: formatCurrency(state.totalReceivables),
                        color: Colors.red.shade700,
                        icon: Icons.account_balance_wallet,
                      ),
                      const SizedBox(width: 12),
                      _SummaryCard(
                        label: 'Total Collected',
                        value: formatCurrency(state.totalCollected),
                        color: Colors.green.shade700,
                        icon: Icons.check_circle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _SummaryCard(
                        label: 'Clients',
                        value: '${state.clients.length}',
                        color: Colors.blue.shade700,
                        icon: Icons.people,
                      ),
                      const SizedBox(width: 12),
                      _SummaryCard(
                        label: 'Overdue',
                        value: '${state.overdueCount}',
                        color: Colors.orange.shade700,
                        icon: Icons.warning_amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Quick Actions ───────────────────────────────────────
                  Text('Quick Actions',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Clients',
                          icon: Icons.people_alt,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ClientsScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: 'Transactions',
                          icon: Icons.receipt_long,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TransactionsScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Overdue List ────────────────────────────────────────
                  if (overdue.isNotEmpty) ...[
                    Text('Overdue Transactions',
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700)),
                    const SizedBox(height: 8),
                    ...overdue.map((txn) {
                      final client = state.getClient(txn.clientId);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade100,
                            child: Icon(Icons.warning,
                                color: Colors.red.shade700, size: 20),
                          ),
                          title: Text(client?.name ?? 'Unknown'),
                          subtitle: Text(
                              'Due: ${formatDate(txn.dueDate)} · Balance: ${formatCurrency(txn.remainingBalance)}'),
                          trailing: Icon(Icons.chevron_right,
                              color: Colors.grey.shade400),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionsScreen(
                                  filterClientId: txn.clientId),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],

                  // ── Recent Transactions ─────────────────────────────────
                  Text('Recent Transactions',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...state.transactions.take(5).map((txn) {
                    final client = state.getClient(txn.clientId);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor(txn.status).withOpacity(0.15),
                          child: Icon(Icons.receipt,
                              color: statusColor(txn.status), size: 20),
                        ),
                        title: Text(client?.name ?? 'Unknown'),
                        subtitle: Text(
                            '${txn.statusLabel} · ${formatCurrency(txn.remainingBalance)} left'),
                        trailing: Text(
                          formatDate(txn.dueDate),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}