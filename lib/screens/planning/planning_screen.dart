// lib/screens/planning/planning_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/balance_service.dart';
import '../../services/reserved_money_service.dart';
import '../../services/current_account_service.dart';
import '../../models/reserved_money.dart';
import '../../models/enums/reserved_money_type.dart';
import 'goals_screen.dart';
import '../../services/goal_schedule_service.dart';

class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isTablet = screenWidth >= 600;

    final currentAccountService = CurrentAccountService();
    final accountId = currentAccountService.getFirstActiveAccountId();
    final goalScheduleService = GoalScheduleService();

    final dueGoals = goalScheduleService.getDueGoals();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              Text(
                t.moneyPlanning,
                style: TextStyle(
                  fontSize: isTablet ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                t.planTrackAchieve,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
              const SizedBox(height: 20),

              if (dueGoals.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.2),
                        Colors.orange.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.notifications_active,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${dueGoals.length} scheduled goal(s) due',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...dueGoals.map(
                        (goal) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• ${goal.title} | ${goal.reserveMoney ? "Reserve" : "Saving"} | ${goal.contributionAmount ?? 0} EGP',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 6),

              // Summary Cards (Horizontal)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _summaryCard(
                      context: context,
                      title: t.budget,
                      subtitle: t.stayOnTrack,
                      value: "4,300 / 7,000",
                      color: Colors.green,
                      icon: Icons.pie_chart,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B3D2E), Color(0xFF0F5C3A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GoalsScreen()),
                        );
                      },
                      child: _summaryCard(
                        context: context,
                        title: t.goals,
                        subtitle: t.makingProgress,
                        value: "8,500",
                        color: Colors.purple,
                        icon: Icons.flag,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2D1B4E), Color(0xFF4A2B7A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _summaryCard(
                      context: context,
                      title: 'Recurring',
                      subtitle: 'Scheduled items',
                      value: '12',
                      color: Colors.blue,
                      icon: Icons.repeat,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A2A4A), Color(0xFF0F3D6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildActionsRequiredCard(),

              const SizedBox(height: 16),

              _buildComingUpCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String value,
    required Color color,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.28).clamp(110.0, 150.0);

    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsRequiredCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withOpacity(0.8),
            const Color(0xFF16213E).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Actions Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _actionTile(
            icon: Icons.credit_card,
            title: 'Visa Payment',
            amount: '1,200 EGP',
            color: Colors.red,
          ),
          const Divider(color: Colors.white12, height: 1),
          _actionTile(
            icon: Icons.flag,
            title: 'Car Goal',
            amount: '500 EGP',
            color: Colors.orange,
          ),
          const Divider(color: Colors.white12, height: 1),
          _actionTile(
            icon: Icons.repeat,
            title: 'Netflix',
            amount: '250 EGP',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildComingUpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A1F2E).withOpacity(0.8),
            const Color(0xFF0F2A3A).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.blue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Coming Up',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _actionTile(
            icon: Icons.payments,
            title: 'Salary',
            amount: '+12,000 EGP',
            color: Colors.green,
          ),
          const Divider(color: Colors.white12, height: 1),
          _actionTile(
            icon: Icons.home,
            title: 'Rent Income',
            amount: '+3,500 EGP',
            color: Colors.green,
          ),
          const Divider(color: Colors.white12, height: 1),
          _actionTile(
            icon: Icons.account_balance,
            title: 'Loan Installment',
            amount: '-800 EGP',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String amount,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
