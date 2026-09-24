import '../core/planning/ports/allocation_repository.dart';
import '../financial_engine/engine/financial_operation_engine.dart';
import '../financial_engine/ports/balance_port.dart';
import '../financial_engine/ports/traceability_port.dart';
import '../infrastructure/memory/memory_journal_entry_repository.dart';

final class FinancialEngineContext {
  final FinancialOperationEngine engine;
  final MemoryJournalEntryRepository repository;
  final AllocationRepository allocationRepository;
  final BalancePort balancePort;
  final TraceabilityPort traceabilityPort;

  const FinancialEngineContext({
    required this.engine,
    required this.repository,
    required this.allocationRepository,
    required this.balancePort,
    required this.traceabilityPort,
  });
}
