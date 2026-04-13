import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/app_state.dart';
import '../models/client.dart';
import 'client_detail_screen.dart';
import 'add_edit_client_screen.dart';
import 'package:provider/provider.dart';

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
    final filtered = state.clients
        .where((c) =>
            c.name.toLowerCase().contains(_search.toLowerCase()) ||
            c.contactNumber.contains(_search))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditClientScreen()),
        ),
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search clients…',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No clients yet. Tap + to add one.'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) =>
                        _ClientTile(client: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  final Client client;
  const _ClientTile({required this.client});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final txns = state.getClientTransactions(client.id);
    final active = txns.where((t) => t.status.name != 'fullyPaid').length;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: client.profileImagePath != null
            ? AssetImage(client.profileImagePath!) as ImageProvider
            : null,
        child: client.profileImagePath == null
            ? Text(client.name[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold))
            : null,
      ),
      title: Text(client.name),
      subtitle: Text('${client.contactNumber} · $active active credit(s)'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ClientDetailScreen(clientId: client.id)),
      ),
    );
  }
}