import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ExpensesIncomeTabs extends StatelessWidget {

  final int selectedIndex;
  final Function(int) onChanged;

  const ExpensesIncomeTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

      margin: const EdgeInsets.symmetric(horizontal: 16),

      height: 44,

      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
      ),

      child: Stack(

        children: [

          /// Animated selector
          AnimatedAlign(

            duration: const Duration(milliseconds: 250),

            curve: Curves.easeOut,

            alignment: selectedIndex == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,

            child: Container(

              width: MediaQuery.of(context).size.width / 2 - 16,

              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),

            ),

          ),

          Row(

            children: [

              /// Expenses
              Expanded(

                child: GestureDetector(

                  onTap: () => onChanged(0),

                  child: Center(

                    child: Text(

                      "Expenses",

                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selectedIndex == 0
                            ? Colors.white
                            : Colors.grey,
                      ),

                    ),

                  ),

                ),

              ),

              /// Income
              Expanded(

                child: GestureDetector(

                  onTap: () => onChanged(1),

                  child: Center(

                    child: Text(

                      "Income",

                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selectedIndex == 1
                            ? Colors.white
                            : Colors.grey,
                      ),

                    ),

                  ),

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }

}