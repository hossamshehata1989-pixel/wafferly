// lib/screens/planning/create_goal_screen.dart

import 'package:flutter/material.dart';
import '../../models/enums/goal_type.dart';
import '../../models/enums/goal_frequency.dart';
import '../../models/enums/goal_funding_method.dart';
import '../../services/goal_service.dart';
import '../../models/goal.dart';
import 'package:flutter/services.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final GoalService _goalService = GoalService();
  int currentStep = 1;
  GoalFundingMethod fundingMethod = GoalFundingMethod.saving;

  final _goalNameController = TextEditingController();
  GoalType selectedType = GoalType.manual;
  DateTime? startDate;
  DateTime? targetDate;

  final _targetAmountController = TextEditingController();
  final _periodAmountController = TextEditingController();

  GoalFrequency frequency = GoalFrequency.monthly;
  String planningMode = 'amount';

  // Helper: accurate months difference
  int _monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  String get _goalEmoji {
    final name = _goalNameController.text.toLowerCase();
    if (name.contains('car') ||
        name.contains('vehicle') ||
        name.contains('سيارة') ||
        name.contains('عربية') ||
        name.contains('عربيه')) {
      return '🚗';
    }
    if (name.contains('travel') ||
        name.contains('trip') ||
        name.contains('vacation') ||
        name.contains('holiday') ||
        name.contains('سفر') ||
        name.contains('رحلة') ||
        name.contains('رحله') ||
        name.contains('مصيف')) {
      return '✈️';
    }
    if (name.contains('house') ||
        name.contains('home') ||
        name.contains('apartment') ||
        name.contains('بيت') ||
        name.contains('منزل') ||
        name.contains('شقة') ||
        name.contains('شقه')) {
      return '🏠';
    }
    if (name.contains('phone') ||
        name.contains('mobile') ||
        name.contains('iphone') ||
        name.contains('android') ||
        name.contains('تليفون') ||
        name.contains('موبايل') ||
        name.contains('هاتف')) {
      return '📱';
    }
    if (name.contains('laptop') ||
        name.contains('computer') ||
        name.contains('pc') ||
        name.contains('كمبيوتر') ||
        name.contains('لاب') ||
        name.contains('لابتوب')) {
      return '💻';
    }
    if (name.contains('education') ||
        name.contains('study') ||
        name.contains('course') ||
        name.contains('جامعة') ||
        name.contains('جامعه') ||
        name.contains('تعليم') ||
        name.contains('دراسة') ||
        name.contains('دراسه')) {
      return '🎓';
    }
    if (name.contains('wedding') ||
        name.contains('marriage') ||
        name.contains('زواج') ||
        name.contains('جواز')) {
      return '💍';
    }
    if (name.contains('baby') ||
        name.contains('child') ||
        name.contains('طفل') ||
        name.contains('بيبي')) {
      return '👶';
    }
    if (name.contains('investment') ||
        name.contains('invest') ||
        name.contains('استثمار')) {
      return '📈';
    }
    if (name.contains('emergency') ||
        name.contains('emergency fund') ||
        name.contains('طوارئ') ||
        name.contains('طارئ')) {
      return '🛟';
    }
    if (name.contains('gift') || name.contains('هدية') || name.contains('هديه')) {
      return '🎁';
    }
    return '🎯';
  }

  @override
  void initState() {
    super.initState();

    startDate = DateTime.now();

    _goalNameController.addListener(() => setState(() {}));
    _targetAmountController.addListener(() => setState(() {}));
    _periodAmountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    _targetAmountController.dispose();
    _periodAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),

          onPressed: () {
            if (currentStep > 1) {
              setState(() {
                currentStep--;
              });
              return;
            }

            Navigator.pop(context);
          },
        ),

        title: const Text(
          'New Goal',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildStepper(),
              const SizedBox(height: 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: currentStep == 1
                      ? _buildStepOne()
                      : currentStep == 2
                      ? _buildStepTwo()
                      : _buildReviewStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double get _targetAmount =>
      double.tryParse(_targetAmountController.text) ?? 0;
  double get _periodAmount =>
      double.tryParse(_periodAmountController.text) ?? 0;

  Widget _buildStepTwo() => _buildGoalBehaviorStep();

  Widget _buildGoalBehaviorStep() {
    // Manual Goal: only target amount
    if (selectedType == GoalType.manual) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How will this goal work?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (fundingMethod == GoalFundingMethod.saving
                            ? Colors.green
                            : Colors.orange)
                        .withOpacity(0.15),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Icon(
                    fundingMethod == GoalFundingMethod.saving
                        ? Icons.savings
                        : Icons.lock,
                    color: fundingMethod == GoalFundingMethod.saving
                        ? Colors.green
                        : Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    fundingMethod == GoalFundingMethod.saving
                        ? 'Real Saving'
                        : 'Reserve Money',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _goalTypeCard(
                    title: 'Manual Goal',
                    subtitle: 'Save anytime',
                    icon: Icons.touch_app,
                    selected: selectedType == GoalType.manual,
                    onTap: () => setState(() => selectedType = GoalType.manual),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _goalTypeCard(
                    title: 'Scheduled Goal',
                    subtitle: 'Reminder based',
                    icon: Icons.schedule,
                    selected: selectedType == GoalType.recurring,
                    onTap: () =>
                        setState(() => selectedType = GoalType.recurring),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,

              child: _buildGradientButton(
                onPressed: () => setState(() => currentStep = 3),
                label: 'Continue',
              ),
            ),
          ],
        ),
      );
    }

    // Scheduled Goal (recurring)
    final periodsNeeded = _periodAmount > 0
        ? (_targetAmount / _periodAmount).ceil()
        : 0;

    int availablePeriods = 0;
    if (targetDate != null && planningMode == 'date') {
      final baseDate = startDate ?? DateTime.now();
      if (frequency == GoalFrequency.monthly) {
        availablePeriods = _monthsBetween(baseDate, targetDate!);
      } else {
        availablePeriods = ((targetDate!.difference(baseDate).inDays) / 7)
            .ceil();
      }
      if (availablePeriods < 0) availablePeriods = 0;
    }
    final requiredSaving = availablePeriods > 0
        ? (_targetAmount / availablePeriods)
        : 0.0;
    final achievable = availablePeriods > 0 && requiredSaving <= 50000;
    DateTime? estimatedEndDate;
    if (startDate != null && periodsNeeded > 0) {
      if (frequency == GoalFrequency.monthly) {
        estimatedEndDate = DateTime(
          startDate!.year,
          startDate!.month + periodsNeeded,
          startDate!.day,
        );
      } else {
        estimatedEndDate = startDate!.add(Duration(days: periodsNeeded * 7));
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How will this goal work?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (fundingMethod == GoalFundingMethod.saving
                          ? Colors.green
                          : Colors.orange)
                      .withOpacity(0.15),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Icon(
                  fundingMethod == GoalFundingMethod.saving
                      ? Icons.savings
                      : Icons.lock,
                  color: fundingMethod == GoalFundingMethod.saving
                      ? Colors.green
                      : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  fundingMethod == GoalFundingMethod.saving
                      ? 'Real Saving'
                      : 'Reserve Money',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _goalTypeCard(
                  title: 'Manual Goal',
                  subtitle: 'Save anytime',
                  icon: Icons.touch_app,
                  selected: selectedType == GoalType.manual,
                  onTap: () => setState(() => selectedType = GoalType.manual),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _goalTypeCard(
                  title: 'Scheduled Goal',
                  subtitle: 'Reminder based',
                  icon: Icons.schedule,
                  selected: selectedType == GoalType.recurring,
                  onTap: () =>
                      setState(() => selectedType = GoalType.recurring),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Planning method only for scheduled goal
          const Text(
            'Choose Planning Method',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _planningMethodCard(
                  title: 'I know how much I can save',
                  icon: Icons.savings,
                  selected: planningMode == 'amount',
                  onTap: () => setState(() => planningMode = 'amount'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _planningMethodCard(
                  title: 'I know when I need it',
                  icon: Icons.flag,
                  selected: planningMode == 'date',
                  onTap: () => setState(() => planningMode = 'date'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Frequency',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SegmentedButton<GoalFrequency>(
            segments: const [
              ButtonSegment(value: GoalFrequency.weekly, label: Text('Weekly')),
              ButtonSegment(
                value: GoalFrequency.monthly,
                label: Text('Monthly'),
              ),
            ],
            selected: {frequency},
            onSelectionChanged: (value) =>
                setState(() => frequency = value.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.white10,
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: const Color(0xFFB794F4),
            ),
          ),
          const SizedBox(height: 24),

          if (planningMode == 'amount') ...[
            const SizedBox(height: 28),
            _buildTextField(
              controller: _targetAmountController,

              label: 'Target Amount',
              prefix: 'EGP',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _periodAmountController,
              label: 'Amount Per Period',

              errorText: _periodAmount > _targetAmount && _targetAmount > 0
                  ? 'Contribution amount cannot exceed target amount'
                  : null,

              prefix: 'EGP',
            ),
          ],
          if (planningMode == 'date') ...[
            const SizedBox(height: 20),
            _buildDateTile(
              title: 'Need By Date',
              value: targetDate,
              onTap: () async {
                if (startDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select Start Date first'),
                    ),
                  );
                  return;
                }
                final date = await showDatePicker(
                  context: context,
                  firstDate: startDate!.add(const Duration(days: 1)),
                  lastDate: DateTime(2100),
                  initialDate:
                      targetDate ?? startDate!.add(const Duration(days: 30)),
                );
                if (date != null) {
                  if (date.isBefore(startDate!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Need By Date must be after Start Date'),
                      ),
                    );
                    return;
                  }
                  setState(() => targetDate = date);
                }
              },
            ),
          ],
          const SizedBox(height: 24),
          _buildTextField(
            controller: _targetAmountController,
            label: 'Target Amount',
            prefix: 'EGP',
          ),
          if (_targetAmount > 0 &&
              (_periodAmount > 0 || planningMode == 'date'))
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: _buildProjectionCard(
                targetAmount: _targetAmount,
                periodAmount: _periodAmount,
                frequency: frequency,
                planningMode: planningMode,
                periodsNeeded: periodsNeeded,
                estimatedEndDate: estimatedEndDate,
                availablePeriods: availablePeriods,
                requiredSaving: requiredSaving,
                targetDate: targetDate,
              ),
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: _buildGradientButton(
              onPressed: () {
                if (selectedType == GoalType.recurring &&
                    planningMode == 'amount' &&
                    _periodAmount > _targetAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Contribution amount cannot exceed target amount',
                      ),
                      backgroundColor: Color.fromARGB(255, 170, 118, 114),
                    ),
                  );
                  return;
                }

                setState(() => currentStep = 3);
              },
              label: 'Continue',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    String? errorText,
  }) {
    return TextField(
      controller: controller,

      keyboardType: const TextInputType.numberWithOptions(decimal: true),

      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],

      style: const TextStyle(color: Colors.white, fontSize: 16),

      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),

        prefixText: prefix != null ? '$prefix ' : null,
        prefixStyle: const TextStyle(color: Colors.white70),

        errorText: errorText,

        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),

        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFB794F4), width: 2),
        ),
      ),
    );
  }

  Widget _buildDateTile({
    required String title,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value == null
            ? 'Select Date'
            : '${value.year}-${value.month}-${value.day}',
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: const Icon(Icons.calendar_month, color: Colors.white70),
      onTap: onTap,
    );
  }

  Widget _buildProjectionCard({
    required double targetAmount,
    required double periodAmount,
    required GoalFrequency frequency,
    required String planningMode,
    required int periodsNeeded,
    DateTime? estimatedEndDate,
    required int availablePeriods,
    required double requiredSaving,
    DateTime? targetDate,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white10, Colors.white10],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Projection',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (planningMode == 'amount') ...[
            _infoRow(
              'Target',
              '${targetAmount.toStringAsFixed(0)} EGP',
              Colors.white70,
            ),
            const SizedBox(height: 8),
            _infoRow(
              '${frequency == GoalFrequency.monthly ? 'Monthly' : 'Weekly'} Saving',
              '${periodAmount.toStringAsFixed(0)} EGP',
              Colors.white70,
            ),
            const SizedBox(height: 12),
            _infoRow(
              'Goal reached after',
              '$periodsNeeded ${periodsNeeded == 1 ? 'period' : 'periods'}',
              Colors.green,
              isBold: true,
            ),

            if (estimatedEndDate != null)
              _infoRow(
                'Estimated End',
                '${estimatedEndDate.year}-${estimatedEndDate.month}-${estimatedEndDate.day}',
                Colors.lightGreen,
                isBold: true,
              ),
          ] else ...[
            _infoRow(
              'Target',
              '${targetAmount.toStringAsFixed(0)} EGP',
              Colors.white70,
            ),
            if (targetDate != null)
              _infoRow(
                'Need By',
                '${targetDate.year}-${targetDate.month}-${targetDate.day}',
                Colors.white70,
              ),
            const SizedBox(height: 12),
            _infoRow(
              'Available Periods',
              '$availablePeriods',
              Colors.green,
              isBold: true,
            ),
            if (availablePeriods > 0)
              _infoRow(
                'Required $frequency Saving',
                '${requiredSaving.toStringAsFixed(0)} EGP',
                Colors.white70,
              ),
            const SizedBox(height: 10),

            _infoRow(
              'Required ${frequency == GoalFrequency.monthly ? 'Monthly' : 'Weekly'} Saving',
              '${requiredSaving.toStringAsFixed(0)} EGP',
              Colors.orange,
              isBold: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white54, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: [
        _stepCircle(1, currentStep >= 1),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: currentStep >= 2
                    ? [const Color(0xFFB794F4), const Color(0xFFB794F4)]
                    : [Colors.white24, Colors.white24],
              ),
            ),
          ),
        ),
        _stepCircle(2, currentStep >= 2),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: currentStep >= 3
                    ? [const Color(0xFFB794F4), const Color(0xFFB794F4)]
                    : [Colors.white24, Colors.white24],
              ),
            ),
          ),
        ),
        _stepCircle(3, currentStep >= 3),
      ],
    );
  }

  Widget _stepCircle(int step, bool active) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active
            ? const LinearGradient(
                colors: [Color(0xFFB794F4), Color(0xFF9B59B6)],
              )
            : null,
        color: active ? null : Colors.white24,
      ),
      child: Center(
        child: Text(
          '$step',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStepOne() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are you saving for?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white12, Colors.white10],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(_goalEmoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
          ),
          const SizedBox(height: 36),
          TextField(
            controller: _goalNameController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Goal Name',
              labelStyle: const TextStyle(color: Colors.white54),
              hintText: 'e.g., Buy a car',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFFB794F4),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          const Text(
            'Funding Method',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _savingMethodCard(
            title: 'Real Saving',
            subtitle: 'Transfer money to a saving account',
            icon: Icons.savings,
            selected: fundingMethod == GoalFundingMethod.saving,
            onTap: () =>
                setState(() => fundingMethod = GoalFundingMethod.saving),
          ),
          const SizedBox(height: 16),
          _savingMethodCard(
            title: 'Reserve Money',
            subtitle: 'Reserve money inside your accounts',
            icon: Icons.lock,
            selected: fundingMethod == GoalFundingMethod.reserve,
            onTap: () =>
                setState(() => fundingMethod = GoalFundingMethod.reserve),
          ),
          const SizedBox(height: 40),
          _buildGradientButton(
            onPressed: () {
              if (_goalNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a goal name')),
                );
                return;
              }
              setState(() => currentStep = 2);
            },
            label: 'Continue',
          ),
        ],
      ),
    );
  }

  Widget _goalTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFB794F4).withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFFB794F4) : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFB794F4).withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planningMethodCard({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFB794F4).withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFB794F4) : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _savingMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFB794F4).withOpacity(0.12)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFFB794F4) : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFB794F4).withOpacity(0.2),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB794F4), Color(0xFF9B59B6)],
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB794F4).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Goal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Text(_goalEmoji, style: const TextStyle(fontSize: 40)),

                const SizedBox(height: 4),

                Text(
                  _goalNameController.text,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _reviewRow(
            'Funding Method',
            fundingMethod == GoalFundingMethod.saving
                ? 'Real Saving'
                : 'Reserve Money',
          ),

          _reviewRow(
            'Goal Type',
            selectedType == GoalType.manual ? 'Manual Goal' : 'Scheduled Goal',
          ),

          if (selectedType == GoalType.recurring)
            _reviewRow(
              'Planning Method',
              planningMode == 'amount' ? 'Amount Based' : 'Date Based',
            ),

          if (selectedType == GoalType.recurring)
            _reviewRow(
              'Frequency',
              frequency == GoalFrequency.monthly ? 'Monthly' : 'Weekly',
            ),

          _reviewRow(
            'Target Amount',
            '${_targetAmount.toStringAsFixed(0)} EGP',
          ),

          if (planningMode == 'amount' && _periodAmount > 0)
            _reviewRow(
              'Amount Per Period',
              '${_periodAmount.toStringAsFixed(0)} EGP',
            ),

          if (planningMode == 'date' && targetDate != null)
            _reviewRow(
              'Need By Date',
              '${targetDate!.year}-${targetDate!.month}-${targetDate!.day}',
            ),

          const SizedBox(height: 24),

          const Text(
            'Projection Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          if (planningMode == 'amount' && _periodAmount > 0) ...[
            _reviewRow(
              'Goal Reached After',
              '${(_targetAmount / _periodAmount).ceil()} periods',
            ),

            if (startDate != null)
              _reviewRow(
                'Estimated End',
                '${DateTime(startDate!.year, startDate!.month + (_targetAmount / _periodAmount).ceil(), startDate!.day).year}-'
                    '${DateTime(startDate!.year, startDate!.month + (_targetAmount / _periodAmount).ceil(), startDate!.day).month}-'
                    '${DateTime(startDate!.year, startDate!.month + (_targetAmount / _periodAmount).ceil(), startDate!.day).day}',
              ),
          ],

          if (planningMode == 'date' && targetDate != null) ...[
            _reviewRow(
              'Need By',
              '${targetDate!.year}-${targetDate!.month}-${targetDate!.day}',
            ),

            _reviewRow(
              'Required Saving',
              '${(_targetAmount / (_monthsBetween(startDate!, targetDate!))).ceil()} EGP',
            ),
          ],

          const SizedBox(height: 24),

          _buildGradientButton(
            onPressed: () async {
              final goal = Goal.create(
                title: _goalNameController.text.trim(),
                targetAmount: _targetAmount,
                type: selectedType,
                targetDate: targetDate,
                reserveMoney: fundingMethod == GoalFundingMethod.reserve,

                recurringRule: selectedType == GoalType.recurring
                    ? frequency.name
                    : null,

                contributionAmount:
                    selectedType == GoalType.recurring &&
                        planningMode == 'amount'
                    ? _periodAmount
                    : null,

                nextDueDate: selectedType == GoalType.recurring
                    ? startDate
                    : null,
              );

              if (selectedType == GoalType.recurring &&
                  planningMode == 'amount' &&
                  _periodAmount > _targetAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Contribution amount cannot exceed target amount',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              await _goalService.add(goal);

              if (!mounted) return;

              Navigator.pop(context);
            },
            label: 'Create Goal',
          ),
        ],
      ),
    );
  }
}
