import 'dart:io';

void main() {
  const base = 'lib/core/planning';

  final folders = [
    '$base/engine',
    '$base/engine/interpreter',
    '$base/engine/guards',
    '$base/engine/policies',
    '$base/engine/planner',
    '$base/engine/integrity',
    '$base/engine/executor',

    '$base/operations',

    '$base/entities',

    '$base/value_objects',

    '$base/ports',

    '$base/infrastructure',
    '$base/infrastructure/repositories',

    '$base/projections',

    '$base/bootstrap',
  ];

  final files = [
    '$base/engine/planning_engine.dart',

    '$base/engine/interpreter/planning_interpreter.dart',

    '$base/engine/guards/planning_guard.dart',
    '$base/engine/guards/planning_guard_pipeline.dart',

    '$base/engine/policies/planning_policy.dart',
    '$base/engine/policies/planning_policy_pipeline.dart',

    '$base/engine/planner/planning_planner.dart',
    '$base/engine/planner/planning_execution_plan.dart',

    '$base/engine/integrity/planning_integrity_checker.dart',

    '$base/engine/executor/planning_executor.dart',

    '$base/operations/planning_operation.dart',
    '$base/operations/reserve_operation.dart',
    '$base/operations/release_operation.dart',
    '$base/operations/reallocate_operation.dart',

    '$base/entities/allocation.dart',

    '$base/value_objects/allocation_version.dart',

    '$base/ports/allocation_repository.dart',

    '$base/infrastructure/repositories/hive_allocation_repository.dart',

    '$base/projections/available_balance_projection.dart',
    '$base/projections/goal_funding_projection.dart',
    '$base/projections/budget_projection.dart',
    '$base/projections/virtual_saving_projection.dart',

    '$base/bootstrap/planning_engine_bootstrap.dart',
  ];

  for (final folder in folders) {
    Directory(folder).createSync(recursive: true);
    print('📁 $folder');
  }

  for (final file in files) {
    final f = File(file);

    if (!f.existsSync()) {
      f.createSync(recursive: true);
      print('📄 $file');
    }
  }

  print('');
  print('================================');
  print('Planning Engine Created');
  print('================================');
}
