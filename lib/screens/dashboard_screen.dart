import 'package:flutter/material.dart';
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
      backgroundColor: theme.colorScheme.surface,
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: state.init,
              child: CustomScrollView(
                slivers: [
                  // --- 1. MODERN HEADER ---
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: true,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: theme.colorScheme.surface,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hello, Admin 👋',
                                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                            Text('Dashboard',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w900, fontSize: 28)),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                        ),
                      )
                    ],
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- 2. HERO TOTAL BALANCE CARD ---
                          _MainBalanceCard(state: state),
                          const SizedBox(height: 24),

                          // --- 3. STATS ROW ---
                          Row(
                            children: [
                              _MiniStat(
                                  label: "Clients",
                                  value: "${state.clients.length}",
                                  icon: Icons.people_alt_rounded,
                                  color: Colors.blue),
                              const SizedBox(width: 12),
                              _MiniStat(
                                  label: "Overdue",
                                  value: "${state.overdueCount}",
                                  icon: Icons.error_outline_rounded,
                                  color: Colors.orange),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // --- 4. OVERDUE SECTION ---
                          if (overdue.isNotEmpty) ...[
                            _SectionHeader(title: "Attention Required", color: Colors.red),
                            const SizedBox(height: 12),
                            ...overdue.map((txn) => _OverdueCard(txn: txn)),
                            const SizedBox(height: 24),
                          ],

                          // --- 5. RECENT ACTIVITY ---
                          _SectionHeader(title: "Recent History"),
                          const SizedBox(height: 12),
                          ...state.transactions.take(5).map((txn) => _TransactionTile(txn: txn)),
                          
                          // Space for the floating bottom bar
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// --- MODERN SUB-COMPONENTS ---

class _MainBalanceCard extends StatelessWidget {
  final AppState state;
  const _MainBalanceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, const Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Collected Today',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(formatCurrency(state.totalCollected),
              style: const TextStyle(
                  color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Receivables', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    Text(formatCurrency(state.totalReceivables),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  const _SectionHeader({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color ?? const Color(0xFF1E293B),
        ));
  }
}

class _OverdueCard extends StatelessWidget {
  final dynamic txn;
  const _OverdueCard({required this.txn});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final client = state.getClient(txn.clientId);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.red, radius: 4),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Delayed by ${DateTime.now().difference(txn.dueDate).inDays} days',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
              ],
            ),
          ),
          Text(formatCurrency(txn.remainingBalance),
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final dynamic txn;
  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final client = state.getClient(txn.clientId);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor(txn.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.receipt_long_rounded, color: statusColor(txn.status), size: 20),
        ),
        title: Text(client?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(formatDate(txn.dueDate), style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatCurrency(txn.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(txn.statusLabel, style: TextStyle(fontSize: 10, color: statusColor(txn.status), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}