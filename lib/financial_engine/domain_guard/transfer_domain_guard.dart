import '../../services/account_service.dart';
import '../interpretation/financial_action_type.dart';
import '../interpretation/normalized_intent.dart';
import 'domain_guard.dart';
import 'domain_guard_result.dart';

/// Domain invariants specific to normal account-to-account transfers.
final class TransferDomainGuard implements DomainGuard {
  final AccountService _accountService;

  const TransferDomainGuard({required AccountService accountService})
    : _accountService = accountService;

  @override
  Future<DomainGuardResult> validate(NormalizedIntent intent) async {
    if (intent.action != FinancialActionType.transfer) {
      return const DomainGuardPassed();
    }

    if (intent.sourceAccountId.trim().isEmpty) {
      return const DomainViolation(reason: 'Source account is required.');
    }

    final destinationId = intent.destinationAccountId;

    if (destinationId == null || destinationId.trim().isEmpty) {
      return const DomainViolation(
        reason: 'Destination account is required.',
      );
    }

    if (intent.sourceAccountId == destinationId) {
      return const DomainViolation(
        reason: 'You cannot transfer money to the same account.',
      );
    }

    if (!intent.amount.isFinite || intent.amount <= 0) {
      return const DomainViolation(
        reason: 'Transfer amount must be greater than zero.',
      );
    }

    final source = _accountService.getById(intent.sourceAccountId);
    final destination = _accountService.getById(destinationId);

    if (source == null) {
      return const DomainViolation(reason: 'Source account was not found.');
    }

    if (destination == null) {
      return const DomainViolation(
        reason: 'Destination account was not found.',
      );
    }

    if (source.isArchived) {
      return const DomainViolation(
        reason: 'The source account is archived and cannot be used.',
      );
    }

    if (destination.isArchived) {
      return const DomainViolation(
        reason: 'The destination account is archived and cannot be used.',
      );
    }

    if (source.bookId != destination.bookId) {
      return const DomainViolation(
        reason: 'You cannot transfer between different books.',
      );
    }

    // FX is not implemented yet. Until it exists, both accounts must use
    // the same currency.
    if (source.currency != destination.currency) {
      return const DomainViolation(
        reason:
            'Transfers between different currencies are not supported yet.',
      );
    }

    return const DomainGuardPassed();
  }
}
