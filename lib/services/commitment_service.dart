import 'package:hive/hive.dart';

import '../models/commitment.dart';

import '../models/enums/commitment_status.dart';

class CommitmentService {
  static const String boxName = 'commitments';

  Box<Commitment> get _box => Hive.box<Commitment>(boxName);

  Future<void> createCommitment(Commitment commitment) async {
    await _box.put(commitment.id, commitment);
  }

  Future<void> updateCommitment(Commitment commitment) async {
    await _box.put(commitment.id, commitment);
  }

  Future<void> archiveCommitment(String commitmentId) async {
    final commitment = _box.get(commitmentId);

    if (commitment == null) return;

    final archived = commitment.copyWith(isArchived: true);
    await _box.put(commitmentId, archived);
  }

  Commitment? getCommitmentById(String commitmentId) {
    return _box.get(commitmentId);
  }

  List<Commitment> getAllCommitments() {
    return _box.values.toList();
  }

  bool exists(String commitmentId) {
    return _box.containsKey(commitmentId);
  }

  // =====================================================
  // Active Commitments
  // =====================================================

  List<Commitment> getActiveCommitments() {
    return _box.values.where((commitment) => !commitment.isArchived).toList();
  }

  // =====================================================
  // Pause
  // =====================================================

  Future<void> pauseCommitment(String commitmentId) async {
    final commitment = _box.get(commitmentId);

    if (commitment == null) return;

    await _box.put(
      commitmentId,
      commitment.copyWith(status: CommitmentStatus.paused),
    );
  }

  // =====================================================
  // Complete
  // =====================================================

  Future<void> completeCommitment(String commitmentId) async {
    final commitment = _box.get(commitmentId);

    if (commitment == null) return;

    await _box.put(
      commitmentId,
      commitment.copyWith(status: CommitmentStatus.completed),
    );
  }

  Future<void> deleteCommitment(String commitmentId) async {
    await _box.delete(commitmentId);
  }
}
