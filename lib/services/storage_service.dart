import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client.dart';
import '../models/transaction.dart';

class StorageService {
  static const _clientsKey = 'creditrack_clients';
  static const _transactionsKey = 'creditrack_transactions';

  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  // ── Clients ──────────────────────────────────────────────────────────────

  Future<List<Client>> loadClients() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_clientsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Client.fromJson(e)).toList();
  }

  Future<void> saveClients(List<Client> clients) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _clientsKey, jsonEncode(clients.map((c) => c.toJson()).toList()));
  }

  Future<void> saveClient(Client client, List<Client> allClients) async {
    final idx = allClients.indexWhere((c) => c.id == client.id);
    if (idx >= 0) {
      allClients[idx] = client;
    } else {
      allClients.add(client);
    }
    await saveClients(allClients);
  }

  Future<void> deleteClient(String id, List<Client> allClients) async {
    allClients.removeWhere((c) => c.id == id);
    await saveClients(allClients);
  }

  // ── Transactions ─────────────────────────────────────────────────────────

  Future<List<CreditTransaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_transactionsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => CreditTransaction.fromJson(e)).toList();
  }

  Future<void> saveTransactions(List<CreditTransaction> txns) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _transactionsKey, jsonEncode(txns.map((t) => t.toJson()).toList()));
  }

  Future<void> saveTransaction(
      CreditTransaction txn, List<CreditTransaction> all) async {
    final idx = all.indexWhere((t) => t.id == txn.id);
    if (idx >= 0) {
      all[idx] = txn;
    } else {
      all.add(txn);
    }
    await saveTransactions(all);
  }

  Future<void> deleteTransaction(
      String id, List<CreditTransaction> all) async {
    all.removeWhere((t) => t.id == id);
    await saveTransactions(all);
  }
}