// lib/services/ledger_service.dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/ledger_entry.dart';

/// خدمة الـ Ledger الأساسية – تخزين وإدارة القيود المحاسبية.
/// NOTE: لم يتم فتح الـ box في main.dart بعد. هذه الطبقة معزولة تماماً عن التطبيق الحالي.
/// سيتم فتح الـ box بشكل صريح أثناء integration phase.
class LedgerService {
  static final LedgerService _instance = LedgerService._internal();
  factory LedgerService() => _instance;
  LedgerService._internal();

  static const String _boxName = 'ledger_entries';

  final _uuid = const Uuid();

  // ==================== Basic CRUD ====================

  /// إنشاء قيد واحد وإضافته إلى الـ box
  Future<void> createEntry(LedgerEntry entry) async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      await box.put(entry.id, entry);
    } catch (e) {
      print("❌ LedgerService: Failed to create entry - $e");
      rethrow;
    }
  }

  /// إنشاء عدة قيود دفعة واحدة
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

  /// الحصول على قيد بواسطة ID
  Future<LedgerEntry?> getEntryById(String id) async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      return box.get(id);
    } catch (e) {
      print("❌ LedgerService: Failed to get entry by id - $e");
      return null;
    }
  }

  /// الحصول على جميع القيود الخاصة بمعاملة معينة (transactionId)
  Future<List<LedgerEntry>> getEntriesByTransactionId(String transactionId) async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      return box.values.where((e) => e.transactionId == transactionId).toList();
    } catch (e) {
      print("❌ LedgerService: Failed to get entries by transactionId - $e");
      return [];
    }
  }

  /// الحصول على جميع القيود الخاصة بحساب معين (accountId)
  Future<List<LedgerEntry>> getEntriesByAccountId(String accountId) async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      return box.values.where((e) => e.accountId == accountId).toList();
    } catch (e) {
      print("❌ LedgerService: Failed to get entries by accountId - $e");
      return [];
    }
  }

  /// الحصول على جميع القيود (بلا ترتيب)
  Future<List<LedgerEntry>> getAllEntries() async {
    try {
      final box = Hive.box<LedgerEntry>(_boxName);
      return box.values.toList();
    } catch (e) {
      print("❌ LedgerService: Failed to get all entries - $e");
      return [];
    }
  }
}