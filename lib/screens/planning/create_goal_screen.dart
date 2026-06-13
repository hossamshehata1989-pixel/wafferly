// lib/screens/planning/create_goal_screen.dart

import 'package:flutter/material.dart';
import '../../models/enums/goal_type.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  int currentStep = 1;
  String fundingMethod = 'saving';

  final _goalNameController = TextEditingController();
  GoalType selectedType = GoalType.manual;
  DateTime? startDate;
  DateTime? targetDate;

  final _targetAmountController = TextEditingController();
  final _periodAmountController = TextEditingController();

  String frequency = 'Monthly';

  String get _goalEmoji {
    final name = _goalNameController.text.toLowerCase();

    // 🚗 Car
    if (name.contains('car') ||
        name.contains('vehicle') ||
        name.contains('سيارة') ||
        name.contains('عربية') ||
        name.contains('عربيه')) {
      return '🚗';
    }

    // ✈️ Travel
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

    // 🏠 Home
    if (name.contains('house') ||
        name.contains('home') ||
        name.contains('apartment') ||
        name.contains('بيت') ||
        name.contains('منزل') ||
        name.contains('شقة') ||
        name.contains('شقه')) {
      return '🏠';
    }

    // 📱 Phone
    if (name.contains('phone') ||
        name.contains('mobile') ||
        name.contains('iphone') ||
        name.contains('android') ||
        name.contains('تليفون') ||
        name.contains('موبايل') ||
        name.contains('هاتف')) {
      return '📱';
    }

    // 💻 Laptop
    if (name.contains('laptop') ||
        name.contains('computer') ||
        name.contains('pc') ||
        name.contains('كمبيوتر') ||
        name.contains('لاب') ||
        name.contains('لابتوب')) {
      return '💻';
    }

    // 🎓 Education
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

    // 💍 Wedding
    if (name.contains('wedding') ||
        name.contains('marriage') ||
        name.contains('زواج') ||
        name.contains('جواز')) {
      return '💍';
    }

    // 👶 Baby
    if (name.contains('baby') ||
        name.contains('child') ||
        name.contains('طفل') ||
        name.contains('بيبي')) {
      return '👶';
    }

    // 📈 Investment
    if (name.contains('investment') ||
        name.contains('invest') ||
        name.contains('استثمار')) {
      return '📈';
    }

    // 🛟 Emergency Fund
    if (name.contains('emergency') ||
        name.contains('emergency fund') ||
        name.contains('طوارئ') ||
        name.contains('طارئ')) {
      return '🛟';
    }

    // 🎁 Gift
    if (name.contains('gift') ||
        name.contains('هدية') ||
        name.contains('هديه')) {
      return '🎁';
    }

    return '🎯';
  }

  @override
  void initState() {
    super.initState();

    _goalNameController.addListener(() {
      setState(() {});
    });

    _targetAmountController.addListener(() {
      setState(() {});
    });

    _periodAmountController.addListener(() {
      setState(() {});
    });
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
        title: const Text('New Goal'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildStepper(),
              const SizedBox(height: 10),
              Expanded(
                child: currentStep == 1 ? _buildStepOne() : _buildStepTwo(),
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

  Widget _buildStepTwo() {
    return _buildGoalBehaviorStep();
  }

  Widget _buildGoalBehaviorStep() {
    final periodsNeeded = _periodAmount > 0
        ? (_targetAmount / _periodAmount).ceil()
        : 0;

    final expectedSaving = periodsNeeded * _periodAmount;

    final overTarget = expectedSaving - _targetAmount;

    DateTime? estimatedEndDate;

    if (startDate != null && periodsNeeded > 0) {
      estimatedEndDate = frequency == 'Monthly'
          ? DateTime(
              startDate!.year,
              startDate!.month + periodsNeeded,
              startDate!.day,
            )
          : startDate!.add(Duration(days: periodsNeeded * 7));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How will this goal work?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Icon(
                  fundingMethod == 'saving' ? Icons.savings : Icons.lock,
                  color: fundingMethod == 'saving'
                      ? Colors.green
                      : Colors.orange,
                ),

                const SizedBox(width: 10),

                Text(
                  fundingMethod == 'saving' ? 'Real Saving' : 'Reserve Money',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _goalTypeCard(
                  title: 'Manual Goal',
                  subtitle: 'Save anytime',
                  icon: Icons.touch_app,
                  selected: selectedType == GoalType.manual,
                  onTap: () {
                    setState(() {
                      selectedType = GoalType.manual;
                    });
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _goalTypeCard(
                  title: 'Scheduled Goal',
                  subtitle: 'Reminder based',
                  icon: Icons.schedule,
                  selected: selectedType == GoalType.recurring,
                  onTap: () {
                    setState(() {
                      selectedType = GoalType.recurring;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (selectedType == GoalType.manual) ...[
            TextField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Target Amount'),
            ),
          ],

          if (selectedType == GoalType.recurring) ...[
            const Text(
              'Frequency',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Weekly', label: Text('Weekly')),
                ButtonSegment(value: 'Monthly', label: Text('Monthly')),
              ],
              selected: {frequency},
              onSelectionChanged: (value) {
                setState(() {
                  frequency = value.first;
                });
              },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _periodAmountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Amount Per Period'),
            ),

            const SizedBox(height: 20),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Start Date',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                startDate == null
                    ? 'Select Date'
                    : startDate.toString().split(' ').first,
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: const Icon(Icons.calendar_month, color: Colors.white),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  initialDate: DateTime.now(),
                );

                if (date != null) {
                  setState(() {
                    startDate = date;
                  });
                }
              },
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Need By Date (Optional)',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                targetDate == null
                    ? 'No deadline'
                    : targetDate.toString().split(' ').first,
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: const Icon(Icons.flag, color: Colors.white),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  initialDate: DateTime.now(),
                );

                if (date != null) {
                  setState(() {
                    targetDate = date;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 20),

            TextField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Target Amount'),
            ),

            if (_targetAmount > 0 && _periodAmount > 0) ...[
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Projection',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Target: ${_targetAmount.toStringAsFixed(0)} EGP',
                      style: const TextStyle(color: Colors.white70),
                    ),

                    Text(
                      '${frequency == 'Weekly' ? 'Weekly' : 'Monthly'} Saving: ${_periodAmount.toStringAsFixed(0)} EGP',
                      style: const TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Needed Periods: $periodsNeeded',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Expected Saving: ${expectedSaving.toStringAsFixed(0)} EGP',
                      style: const TextStyle(color: Colors.white70),
                    ),

                    Text(
                      'Over Target: ${overTarget.toStringAsFixed(0)} EGP',
                      style: const TextStyle(color: Colors.orange),
                    ),

                    if (estimatedEndDate != null)
                      Text(
                        'Estimated End: ${estimatedEndDate.toString().split(' ').first}',
                        style: const TextStyle(
                          color: Colors.lightGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                setState(() {
                  currentStep = 3;
                });
              },
              child: const Text('Continue'),
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
        const Expanded(child: Divider()),
        _stepCircle(2, currentStep >= 2),
        const Expanded(child: Divider()),
        _stepCircle(3, currentStep >= 3),
      ],
    );
  }

  Widget _stepCircle(int step, bool active) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: active ? const Color(0xFFB794F4) : Colors.white24,
      child: Text('$step', style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildStepOne() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are you saving for?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          // Goal Icon (placeholder)
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(_goalEmoji, style: const TextStyle(fontSize: 40)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Goal Name
          TextField(
            controller: _goalNameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Goal Name',
              labelStyle: TextStyle(color: Colors.white54),
              hintText: 'e.g., Buy a car',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white30),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFB794F4), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 32),

          const Text(
            'Funding Method',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          _savingMethodCard(
            title: 'Real Saving',
            subtitle: 'Transfer money to a saving account',
            icon: Icons.savings,
            selected: fundingMethod == 'saving',
            onTap: () {
              setState(() {
                fundingMethod = 'saving';
              });
            },
          ),

          const SizedBox(height: 12),

          _savingMethodCard(
            title: 'Reserve Money',
            subtitle: 'Reserve money inside your accounts',
            icon: Icons.lock,
            selected: fundingMethod == 'reserve',
            onTap: () {
              setState(() {
                fundingMethod = 'reserve';
              });
            },
          ),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_goalNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a goal name')),
                  );
                  return;
                }
                setState(() {
                  currentStep = 2;
                });
              },
              child: const Text('Continue'),
            ),
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
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFB794F4).withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFB794F4) : Colors.white12,
          ),
        ),
        child: SizedBox(
          height: 90,
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFB794F4).withOpacity(.15)
              : Colors.white.withOpacity(.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFB794F4) : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),

            const SizedBox(width: 16),

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

                  const SizedBox(height: 6),

                  Text(subtitle, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
