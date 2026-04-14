import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../models/client.dart';
import 'client_detail_screen.dart';
import 'add_edit_client_screen.dart';
import 'package:provider/provider.dart';
import 'dart:io'; // Use File for actual local images

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    
    final filtered = state.clients
        .where((c) =>
            c.name.toLowerCase().contains(_search.toLowerCase()) ||
            c.contactNumber.contains(_search))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      // Custom Modern AppBar
      appBar: AppBar(
        title: const Text('Directory'),
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditClientScreen()),
            ),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Modern Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search by name or number...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length + 1, // +1 for bottom spacing
                    itemBuilder: (ctx, i) {
                      if (i == filtered.length) return const SizedBox(height: 100);
                      return _ClientCard(client: filtered[i]);
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
          Icon(Icons.person_search_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No clients found', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Client client;
  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = Theme.of(context);
    final txns = state.getClientTransactions(client.id);
    final activeCount = txns.where((t) => t.status.name != 'fullyPaid').length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClientDetailScreen(clientId: client.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar Section
              Hero(
                tag: 'avatar-${client.id}',
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                    image: client.profileImagePath != null
                        ? DecorationImage(
                            image: FileImage(File(client.profileImagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: client.profileImagePath == null
                      ? Center(
                          child: Text(
                            client.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              
              // Info Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      client.contactNumber,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              
              // Active Credit Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (activeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$activeCount Active',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'Clear',
                      style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 4),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}