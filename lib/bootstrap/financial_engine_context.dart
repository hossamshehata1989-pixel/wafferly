import '../financial_engine/engine/financial_operation_engine.dart';
import '../infrastructure/memory/memory_allocation_repository.dart';
import '../infrastructure/memory/memory_journal_entry_repository.dart';

final class FinancialEngineContext {
  final FinancialOperationEngine engine;
  final MemoryJournalEntryRepository repository;
  final MemoryAllocationRepository allocationRepository;

  const FinancialEngineContext({
    required this.engine,
    required this.repository,
    required this.allocationRepository,
  });
}
