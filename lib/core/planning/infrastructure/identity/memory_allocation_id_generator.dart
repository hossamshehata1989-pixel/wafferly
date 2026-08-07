import 'package:uuid/uuid.dart';

import '../../ports/allocation_id_generator.dart';

/// ===============================================================
/// MemoryAllocationIdGenerator
/// ===============================================================
///
/// Temporary UUID generator.
///
/// Will later be replaced by the production identity strategy.
///
/// ===============================================================
final class MemoryAllocationIdGenerator implements AllocationIdGenerator {
  MemoryAllocationIdGenerator();

  static const Uuid _uuid = Uuid();

  @override
  String next() => _uuid.v4();
}
