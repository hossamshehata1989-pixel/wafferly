// lib/screens/planning/planning_screen.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 8),

              Text(
                t.moneyPlanning,
                style: TextStyle(
                  fontSize: isTablet ? 32 : 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                t.planTrackAchieve,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),

              const SizedBox(height: 16),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _summaryCard(
                      context: context,
                      title: t.budget,
                      subtitle: t.stayOnTrack,
                      value: "4300 / 7000",
                      color: Colors.green,
                      icon: Icons.pie_chart,
                    ),
                    const SizedBox(width: 12),
                    _summaryCard(
                      context: context,
                      title: t.goals,
                      subtitle: t.makingProgress,
                      value: "8500",
                      color: Colors.purple,
                      icon: Icons.flag,
                    ),
                    const SizedBox(width: 12),
                    _summaryCard(
                      context: context,
                      title: t.reserved,
                      subtitle: t.safetyFirst,
                      value: "6000",
                      color: Colors.orange,
                      icon: Icons.lock,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _reservedHero(context, t, isSmallScreen),

              const SizedBox(height: 24),

              Column(
                children: [
                  _budgetOverview(t),
                  const SizedBox(height: 16),
                  _goalsOverview(t),
                ],
              ),
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
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.28).clamp(100.0, 140.0);

    return SizedBox(
      width: cardWidth,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reservedHero(
    BuildContext context,
    AppLocalizations t,
    bool isSmallScreen,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.lock, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  t.reservedMoney,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            isSmallScreen
                ? Wrap(
                    alignment: WrapAlignment.spaceAround,
                    runSpacing: 12,
                    children: [
                      _balanceItem(
                        t.real,
                        "10000",
                        Colors.green,
                        isSmallScreen,
                      ),
                      _balanceItem(
                        t.reserved,
                        "6000",
                        Colors.orange,
                        isSmallScreen,
                      ),
                      _balanceItem(
                        t.available,
                        "4000",
                        Colors.blue,
                        isSmallScreen,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _balanceItem(
                          t.real,
                          "10000",
                          Colors.green,
                          isSmallScreen,
                        ),
                      ),
                      Expanded(
                        child: _balanceItem(
                          t.reserved,
                          "6000",
                          Colors.orange,
                          isSmallScreen,
                        ),
                      ),
                      Expanded(
                        child: _balanceItem(
                          t.available,
                          "4000",
                          Colors.blue,
                          isSmallScreen,
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 20),
            const Divider(),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t.topReservedItems,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),

            ListTile(
              dense: true,
              leading: const CircleAvatar(child: Icon(Icons.home)),
              title: Text(t.rent, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                t.cashAccount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Text("3000"),
            ),
            ListTile(
              dense: true,
              leading: const CircleAvatar(child: Icon(Icons.credit_card)),
              title: Text(
                t.installment,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                t.credit,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Text("2000"),
            ),
            ListTile(
              dense: true,
              leading: const CircleAvatar(child: Icon(Icons.fastfood)),
              title: Text(
                t.foodBucket,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                t.budget,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Text("1000"),
            ),

            const SizedBox(height: 12),
            FilledButton(onPressed: () {}, child: Text(t.viewAll)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _balanceItem(
    String title,
    String value,
    Color color,
    bool isSmallScreen,
  ) {
    return Column(
      children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
      ],
    );
  }

  // ✅ Mock data: عناصر التخطيط (Budget + Goals)
  final List<_PlanningItem> _budgetItems = const [
    _PlanningItem(
      icon: "🍔",
      titleKey: "food",
      percent: "80%",
      isReserved: true,
    ),
    _PlanningItem(
      icon: "👕",
      titleKey: "shopping",
      percent: "35%",
      isReserved: false,
    ),
    _PlanningItem(
      icon: "🚕",
      titleKey: "transport",
      percent: "90%",
      isReserved: true,
    ),
  ];

  final List<_PlanningItem> _goalItems = const [
    _PlanningItem(
      icon: "✈️",
      titleKey: "travel",
      percent: "30%",
      isReserved: true,
    ),
    _PlanningItem(
      icon: "🚗",
      titleKey: "newCar",
      percent: "10%",
      isReserved: false,
    ),
    _PlanningItem(
      icon: "🎓",
      titleKey: "education",
      percent: "7.5%",
      isReserved: false,
    ),
  ];

  Widget _budgetOverview(AppLocalizations t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.budgetOverview,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: .61),
            const SizedBox(height: 16),
            ..._budgetItems.map((item) => _buildPlanningRow(t, item)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanningRow(AppLocalizations t, _PlanningItem item) {
    String title;
    switch (item.titleKey) {
      case "food":
        title = t.food;
        break;
      case "shopping":
        title = t.shopping;
        break;
      case "transport":
        title = t.transport;
        break;
      case "travel":
        title = t.travel;
        break;
      case "newCar":
        title = t.newCar;
        break;
      case "education":
        title = t.education;
        break;
      default:
        title = item.titleKey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // ✅ العمود الأيسر: الأيقونة + العنوان
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Text(item.icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // ✅ العمود الأوسط: عرض ثابت لـ Chip (يظهر فقط إذا Reserved)
          SizedBox(
            width: 110,
            child: item.isReserved
                ? Chip(
                    label: Text(t.reserved),
                    avatar: const Icon(Icons.lock, size: 14),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  )
                : const SizedBox(),
          ),

          const SizedBox(width: 12),

          // ✅ العمود الأيمن: النسبة المئوية
          Text(
            item.percent,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _goalsOverview(AppLocalizations t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.goalsOverview,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: .24),
            const SizedBox(height: 16),
            ..._goalItems.map((item) => _buildPlanningRow(t, item)),
          ],
        ),
      ),
    );
  }
}

// ✅ إعادة التسمية: _PlanningItem (كانت _BudgetItem)
class _PlanningItem {
  final String icon;
  final String titleKey;
  final String percent;
  final bool isReserved;

  const _PlanningItem({
    required this.icon,
    required this.titleKey,
    required this.percent,
    required this.isReserved,
  });
}
