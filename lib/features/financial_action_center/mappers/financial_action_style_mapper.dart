import 'package:flutter/material.dart';

import '../../../models/enums/scheduled_action_kind.dart';
import '../models/financial_action_style.dart';

class FinancialActionStyleMapper {
  const FinancialActionStyleMapper();

  FinancialActionStyle fromKind(ScheduledActionKind kind) {
    switch (kind) {
      case ScheduledActionKind.expense:
        return const FinancialActionStyle(
          primary: Color(0xFFFF5A5F),
          stripe: Color(0xFFFF5A5F),
          iconBackground: Color(0x33FF5A5F),
          badgeBackground: Color(0x22FF5A5F),
          buttonBackground: Color(0xFFFF5A5F),
        );

      case ScheduledActionKind.income:
        return const FinancialActionStyle(
          primary: Color(0xFF30D158),
          stripe: Color(0xFF30D158),
          iconBackground: Color(0x2230D158),
          badgeBackground: Color(0x2230D158),
          buttonBackground: Color(0xFF30D158),
        );

      case ScheduledActionKind.goalContribution:
        return const FinancialActionStyle(
          primary: Color(0xFF3A7BFF),
          stripe: Color(0xFF3A7BFF),
          iconBackground: Color(0x223A7BFF),
          badgeBackground: Color(0x223A7BFF),
          buttonBackground: Color(0xFF3A7BFF),
        );

      case ScheduledActionKind.transfer:
        return const FinancialActionStyle(
          primary: Color(0xFFFF2D8D),
          stripe: Color(0xFFFF2D8D),
          iconBackground: Color(0x22FF2D8D),
          badgeBackground: Color(0x22FF2D8D),
          buttonBackground: Color(0xFFFF2D8D),
        );

      case ScheduledActionKind.investment:
        return const FinancialActionStyle(
          primary: Color(0xFFFFB800),
          stripe: Color(0xFFFFB800),
          iconBackground: Color(0x22FFB800),
          badgeBackground: Color(0x22FFB800),
          buttonBackground: Color(0xFFFFB800),
        );

      case ScheduledActionKind.liabilityPayment:
        return const FinancialActionStyle(
          primary: Color(0xFF9C275F),
          stripe: Color(0xFF9C275F),
          iconBackground: Color(0x229C275F),
          badgeBackground: Color(0x229C275F),
          buttonBackground: Color(0xFF9C275F),
        );

      case ScheduledActionKind.budgetReset:
        return const FinancialActionStyle(
          primary: Color(0xFF8E8E93),
          stripe: Color(0xFF8E8E93),
          iconBackground: Color(0x228E8E93),
          badgeBackground: Color(0x228E8E93),
          buttonBackground: Color(0xFF8E8E93),
        );
    }
  }
}
