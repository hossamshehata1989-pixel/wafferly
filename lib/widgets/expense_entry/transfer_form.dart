// lib/widgets/expense_entry/transfer_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/transaction_entry_controller.dart';
import '../../models/account.dart';
import '../../l10n/app_localizations.dart';

class TransferForm extends StatefulWidget {
  final TransactionEntryController controller;
  final VoidCallback? onSuccess;

  const TransferForm({
    super.key,
    required this.controller,
    this.onSuccess,
  });

  @override
  State<TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<TransferForm> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _formErrorMessage;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _noteController.addListener(_onNoteChanged);
    widget.controller.addListener(_onControllerChanged);
  }

  void _onAmountChanged() {
    widget.controller.setAmount(_amountController.text);
  }

  void _onNoteChanged() {
    widget.controller.setNote(_noteController.text);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _clearFormError() {
    if (_formErrorMessage != null) {
      setState(() => _formErrorMessage = null);
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _noteController.removeListener(_onNoteChanged);
    widget.controller.removeListener(_onControllerChanged);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final accounts = widget.controller.availableAccounts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(t.fromAccount),
          const SizedBox(height: 8),
          _buildAccountPicker(
            accounts: accounts,
            selectedId: widget.controller.selectedFromAccountId,
            selectedName: widget.controller.selectedFromAccountName,
            onSelect: (id, name) =>
                widget.controller.selectFromAccount(id, name),
            hint: t.selectSourceAccount,
          ),
          const SizedBox(height: 16),
          _buildLabel(t.toAccount),
          const SizedBox(height: 8),
          _buildAccountPicker(
            accounts: accounts,
            selectedId: widget.controller.selectedToAccountId,
            selectedName: widget.controller.selectedToAccountName,
            onSelect: (id, name) => widget.controller.selectToAccount(id, name),
            hint: t.selectDestinationAccount,
          ),
          const SizedBox(height: 16),
          _buildLabel(t.amount),
          const SizedBox(height: 8),
          _buildAmountInput(),
          const SizedBox(height: 16),
          _buildLabel(t.date),
          const SizedBox(height: 8),
          _buildDatePicker(),
          const SizedBox(height: 16),
          _buildLabel(t.notes),
          const SizedBox(height: 8),
          _buildNotesInput(),
          const SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 14),
    );
  }

  Widget _buildAccountPicker({
    required List<Account> accounts,
    required String selectedId,
    required String selectedName,
    required Function(String, String) onSelect,
    required String hint,
  }) {
    if (accounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.noAccountsAvailable,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showAccountPicker(accounts, selectedId, onSelect),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedId.isEmpty ? hint : selectedName,
              style: TextStyle(
                color: selectedId.isEmpty ? Colors.white54 : Colors.white,
                fontSize: 14,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  void _showAccountPicker(
    List<Account> accounts,
    String selectedId,
    Function(String, String) onSelect,
  ) {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.selectAccount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: accounts
                    .map(
                      (acc) => ListTile(
                        leading: Icon(
                          _getAccountIcon(acc.type),
                          color: _getAccountColor(acc.type),
                        ),
                        title: Text(
                          acc.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          acc.type,
                          style: const TextStyle(color: Colors.white54),
                        ),
                        onTap: () {
                          onSelect(acc.id, acc.name);
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Text(
            widget.controller.transferCurrency,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
  controller: _amountController,
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
  ],
  style: const TextStyle(
    color: Colors.white,
    fontSize: 18,
  ),
  decoration: const InputDecoration(
    border: InputBorder.none,
    hintText: '0',
    hintStyle: TextStyle(color: Colors.white54),
  ),
),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: widget.controller.selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF3A7BFF),
                surface: Color(0xFF1B2A6B),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) widget.controller.setSelectedDate(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.controller.selectedDate.day}/${widget.controller.selectedDate.month}/${widget.controller.selectedDate.year}',
              style: const TextStyle(color: Colors.white),
            ),
            const Icon(Icons.calendar_today, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        controller: _noteController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'أضف ملاحظة...',
          hintStyle: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final t = AppLocalizations.of(context)!;
    final isSaving = widget.controller.saveStatus == SaveStatus.saving;
    final errorMessage =
        _formErrorMessage ?? widget.controller.lastErrorMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorMessage != null && errorMessage.trim().isNotEmpty) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withOpacity(0.45)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSaving ? null : () => _saveTransfer(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    t.save,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveTransfer() async {
    final t = AppLocalizations.of(context)!;

    setState(() => _formErrorMessage = null);

    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      setState(() => _formErrorMessage = t.pleaseEnterValidAmount);
      return;
    }

    if (widget.controller.selectedFromAccountId.isEmpty ||
        widget.controller.selectedToAccountId.isEmpty) {
      setState(() => _formErrorMessage = t.selectBothAccounts);
      return;
    }

    if (widget.controller.selectedFromAccountId ==
        widget.controller.selectedToAccountId) {
      setState(() => _formErrorMessage = t.sameAccountError);
      return;
    }

    final success = await widget.controller.saveTransfer();
    if (!mounted) return;

    if (success) {
  _amountController.clear();
  _noteController.clear();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(t.transferSuccess)),
  );

  widget.onSuccess?.call();

  return;
}

    // saveTransfer() stores the exact Financial Engine error in
    // controller.lastErrorMessage. The controller listener rebuilds this
    // form, so the error is displayed inline above the Save button.
    // Keep a generic fallback only if the controller returned no message.
    if (widget.controller.lastErrorMessage == null ||
        widget.controller.lastErrorMessage!.trim().isEmpty) {
      setState(() => _formErrorMessage = t.transferFailed);
    }
  }

  Color _getAccountColor(String type) {
    switch (type) {
      case 'cash':
        return Colors.green;
      case 'bank':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.attach_money;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
