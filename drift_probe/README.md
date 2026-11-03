# Wafferly Drift parser/code-generation probe

This is an isolated probe. It is **not** copied into the Wafferly application and does not change the app's dependencies or source files.

## Candidate package versions

- `drift: 2.35.3`
- `drift_dev: 2.35.2`
- `sqlite3: 3.8.0`
- `build_runner: 2.15.1`
- Dart SDK constraint: `>=3.10.7 <4.0.0`

These are a candidate pin set for dependency resolution, not a verified lockfile. The project currently declares Dart `^3.10.7` and locks `build_runner 2.4.13`, `build 2.4.1`, and `analyzer 6.4.1`. Run the commands below with the actual project Dart SDK before accepting these versions in Wafferly.

## Run

```bash
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart run bin/run_probe.dart
```

Expected checks include generated `.drift` query API, partial index/trigger creation, per-connection foreign-key activation, composite FK rejection, integer-only Minor Units, and transaction rollback.

`NativeDatabase.memory(setup: ...)` enables `PRAGMA foreign_keys = ON` before Drift starts using the SQLite connection. This is essential: SQLite does not guarantee foreign-key enforcement by default.

## Scope / limitations

- `schema_probe.drift` is a representative subset, not Wafferly's production schema.
- The raw SQLite capability tests are in `../representative_schema.sql` and `../run_spike.py`.
- Dart / Flutter and Pub code generation could not be run in the current authoring environment. Therefore this package is prepared for execution, but `.drift` parser and generated Dart API are **not yet verified** here.
- No encryption is included in this probe.
