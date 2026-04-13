import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import '../models/transaction.dart';
import '../models/payment.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  List<Client> _clients = [];
  List<CreditTransaction> _transactions = [];
  bool _loading = true;

  List<Client> get clients => List.unmodifiable(_clients);
  List<CreditTransaction> get transactions => List.unmodifiable(_transactions);
  bool get loading => _loading;

  final _uuid = const Uuid();

  Future<void> init() async {
    _clients = await StorageService.instance.loadClients();
    _transactions = await StorageService.instance.loadTransactions();
    _loading = false;
    notifyListeners();
  }

  // ── Clients ──────────────────────────────────────────────────────────────

  Future<Client> addClient({
    required String name,
    required String contactNumber,
    required String address,
    String? profileImagePath,
  }) async {
    final client = Client(
      id: _uuid.v4(),
      name: name,
      contactNumber: contactNumber,
      address: address,
      profileImagePath: profileImagePath,
    );
    _clients.add(client);
    await StorageService.instance.saveClients(_clients);
    notifyListeners();
    return client;
  }

  Future<void> updateClient(Client client) async {
    final idx = _clients.indexWhere((c) => c.id == client.id);
    if (idx >= 0) _clients[idx] = client;
    await StorageService.instance.saveClients(_clients);
    notifyListeners();
  }

  Future<void> deleteClient(String id) async {
    // Also delete all transactions for this client
    _transactions.removeWhere((t) => t.clientId == id);
    _clients.removeWhere((c) => c.id == id);
    await StorageService.instance.saveClients(_clients);
    await StorageService.instance.saveTransactions(_transactions);
    notifyListeners();
  }

  Client? getClient(String id) {
    try {
      return _clients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CreditTransaction> getClientTransactions(String clientId) =>
      _transactions.where((t) => t.clientId == clientId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // ── Transactions ─────────────────────────────────────────────────────────

  Future<CreditTransaction> addTransaction({
    required String clientId,
    required double amountBorrowed,
    required DateTime dateBorrowed,
    required DateTime dueDate,
    required double interestRate,
    required int monthsToPay,
    required double totalAmount,
    String? notes,
  }) async {
    final txn = CreditTransaction(
      id: _uuid.v4(),
      clientId: clientId,
      amountBorrowed: amountBorrowed,
      dateBorrowed: dateBorrowed,
      dueDate: dueDate,
      interestRate: interestRate,
      monthsToPay: monthsToPay,
      totalAmount: totalAmount,
      notes: notes,
    );
    _transactions.add(txn);
    // Link to client
    final client = getClient(clientId);
    if (client != null) {
      client.transactionIds.add(txn.id);
      await StorageService.instance.saveClients(_clients);
    }
    await StorageService.instance.saveTransactions(_transactions);
    notifyListeners();
    return txn;
  }

  Future<void> addPayment({
    required String transactionId,
    required double amount,
    required DateTime datePaid,
    required PaymentMethod method,
    String? notes,
  }) async {
    final idx = _transactions.indexWhere((t) => t.id == transactionId);
    if (idx < 0) return;
    final payment = Payment(
      id: _uuid.v4(),
      amount: amount,
      datePaid: datePaid,
      method: method,
      notes: notes,
    );
    _transactions[idx].payments.add(payment);
    _transactions[idx].updateStatus();
    await StorageService.instance.saveTransactions(_transactions);
    notifyListeners();
  }

  Future<void> updateTransaction(CreditTransaction txn) async {
    final idx = _transactions.indexWhere((t) => t.id == txn.id);
    if (idx >= 0) _transactions[idx] = txn;
    await StorageService.instance.saveTransactions(_transactions);
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    final txn = _transactions.firstWhere((t) => t.id == id);
    final client = getClient(txn.clientId);
    if (client != null) {
      client.transactionIds.remove(id);
      await StorageService.instance.saveClients(_clients);
    }
    _transactions.removeWhere((t) => t.id == id);
    await StorageService.instance.saveTransactions(_transactions);
    notifyListeners();
  }

  CreditTransaction? getTransaction(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Dashboard stats ───────────────────────────────────────────────────────

  double get totalReceivables => _transactions.fold(
      0.0, (s, t) => s + (t.status != PaymentStatus.fullyPaid ? t.remainingBalance : 0));

  double get totalCollected =>
      _transactions.fold(0.0, (s, t) => s + t.totalPaid);

  int get overdueCount =>
      _transactions.where((t) => t.isOverdue).length;
}