// lib/services/ledger_service.dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/ledger_entry.dart';
import '../models/enums/entry_type.dart';
import '../models/enums/ledger_purpose.dart';

/// خدمة الـ Ledger الأساسية – تخزين وإدارة القيود المحاسبية.
/// ============================================================
/// 📌 Sprint 3D Stabilization:
///    - تم تصنيف الدوال حسب مرحلة الاستخدام
///    - الدوال غير المستخدمة حالياً تم توثيقها كـ "Future Phase"
/// ============================================================
class LedgerService {
  static final LedgerService _instance = LedgerService._internal();
  factory LedgerService() => _instance;
  LedgerService._internal();

  static const String _boxName = 'ledger_entries';
  final _uuid = const Uuid();

  // ============================================================
  // ✅ CORE CRUD (Sprint 3A - 3C) - مستخدم حالياً
  // ============================================================

  Future<void> createEntry(LedgerEntry entry) async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      await box.put(entry.id, entry);
    } catch (e) {
      print("❌ LedgerService: Failed to create entry - $e");
      rethrow;
    }
  }

  Future<void> createEntries(List<LedgerEntry> entries) async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      final Map<String, LedgerEntry> map = {for (var e in entries) e.id: e};
      await box.putAll(map);
    } catch (e) {
      print("❌ LedgerService: Failed to create entries - $e");
      rethrow;
    }
  }

  Future<LedgerEntry?> getEntryById(String id) async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      return box.get(id);
    } catch (e) {
      print("❌ LedgerService: Failed to get entry by id - $e");
      return null;
    }
  }

  Future<List<LedgerEntry>> getEntriesByTransactionId(String transactionId) async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      return box.values.where((e) => e.transactionId == transactionId).toList();
    } catch (e) {
      print("❌ LedgerService: Failed to get entries by transactionId - $e");
      return [];
    }
  }

  Future<List<LedgerEntry>> getEntriesByAccountId(String accountId) async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      return box.values.where((e) => e.accountId == accountId).toList();
    } catch (e) {
      print("❌ LedgerService: Failed to get entries by accountId - $e");
      return [];
    }
  }

  Future<List<LedgerEntry>> getAllEntries() async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      return box.values.toList();
    } catch (e) {
      print("❌ LedgerService: Failed to get all entries - $e");
      return [];
    }
  }

  // ============================================================
  // 🔮 FUTURE PHASE - Balance Engine (Sprint 4+)
  // غير مستخدمة حالياً في production flow
  // ============================================================

  Future<double> getBalanceForAccount(String accountId) async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      double balance = 0;
      for (final entry in box.values) {
        if (entry.accountId == accountId) {
          if (entry.entryType == EntryType.debit) {
            balance += entry.amount;
          } else {
            balance -= entry.amount;
          }
        }
      }
      return balance;
    } catch (e) {
      print("❌ LedgerService: Failed to get balance for account $accountId - $e");
      return 0;
    }
  }

  Future<double> getBalanceForAccountInRange(
    String accountId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      double balance = 0;
      for (final entry in box.values) {
        if (entry.accountId == accountId &&
            entry.date.isAfter(start.subtract(const Duration(days: 1))) &&
            entry.date.isBefore(end.add(const Duration(days: 1)))) {
          if (entry.entryType == EntryType.debit) {
            balance += entry.amount;
          } else {
            balance -= entry.amount;
          }
        }
      }
      return balance;
    } catch (e) {
      print("❌ LedgerService: Failed to get balance for account $accountId in range - $e");
      return 0;
    }
  }

  // ============================================================
  // 🔮 FUTURE PHASE - Analytics & Reporting (Sprint 4+)
  // غير مستخدمة حالياً في production flow
  // ============================================================

  Future<double> getTotalExpenses(DateTime start, DateTime end) async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      double total = 0;
      for (final entry in box.values) {
        if (entry.purpose == LedgerPurpose.expense &&
            entry.entryType == EntryType.debit &&
            entry.date.isAfter(start.subtract(const Duration(days: 1))) &&
            entry.date.isBefore(end.add(const Duration(days: 1)))) {
          total += entry.amount;
        }
      }
      return total;
    } catch (e) {
      print("❌ LedgerService: Failed to get total expenses - $e");
      return 0;
    }
  }

  Future<double> getTotalIncome(DateTime start, DateTime end) async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      double total = 0;
      for (final entry in box.values) {
        if (entry.purpose == LedgerPurpose.income &&
            entry.entryType == EntryType.credit &&
            entry.date.isAfter(start.subtract(const Duration(days: 1))) &&
            entry.date.isBefore(end.add(const Duration(days: 1)))) {
          total += entry.amount;
        }
      }
      return total;
    } catch (e) {
      print("❌ LedgerService: Failed to get total income - $e");
      return 0;
    }
  }

  Future<Map<String, double>> getBalanceByAccount() async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      final Map<String, double> result = {};
      for (final entry in box.values) {
        final current = result[entry.accountId] ?? 0;
        if (entry.entryType == EntryType.debit) {
          result[entry.accountId] = current + entry.amount;
        } else {
          result[entry.accountId] = current - entry.amount;
        }
      }
      return result;
    } catch (e) {
      print("❌ LedgerService: Failed to get balance by account - $e");
      return {};
    }
  }

  Future<Map<LedgerPurpose, double>> getTotalByPurpose() async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      final Map<LedgerPurpose, double> result = {};
      for (final entry in box.values) {
        final current = result[entry.purpose] ?? 0;
        result[entry.purpose] = current + entry.amount;
      }
      return result;
    } catch (e) {
      print("❌ LedgerService: Failed to get total by purpose - $e");
      return {};
    }
  }

  // ============================================================
  // 🧹 FUTURE PHASE - Cleanup Operations (Sprint 5+)
  // غير مستخدمة حالياً
  // ============================================================

  Future<void> deleteEntriesByTransactionId(String transactionId) async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      final keysToDelete = box.keys.where((key) {
        final entry = box.get(key);
        return entry?.transactionId == transactionId;
      }).toList();
      await box.deleteAll(keysToDelete);
    } catch (e) {
      print("❌ LedgerService: Failed to delete entries by transactionId - $e");
      rethrow;
    }
  }

  Future<void> deleteEntriesByAccountId(String accountId) async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      final keysToDelete = box.keys.where((key) {
        final entry = box.get(key);
        return entry?.accountId == accountId;
      }).toList();
      await box.deleteAll(keysToDelete);
    } catch (e) {
      print("❌ LedgerService: Failed to delete entries by accountId - $e");
      rethrow;
    }
  }

  Future<void> deleteAllEntries() async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      await box.clear();
    } catch (e) {
      print("❌ LedgerService: Failed to delete all entries - $e");
      rethrow;
    }
  }

  Future<int> get count async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      return box.length;
    } catch (e) {
      print("❌ LedgerService: Failed to get count - $e");
      return 0;
    }
  }
}