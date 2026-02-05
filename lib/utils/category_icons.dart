import 'package:flutter/material.dart';

IconData getMainCategoryIcon(String key) {
  switch (key) {
    case 'transport': return Icons.directions_bus;
    case 'bills': return Icons.receipt_long;
    case 'supermarket': return Icons.local_grocery_store;
    case 'eat_out': return Icons.restaurant;
    case 'meat_fish': return Icons.set_meal;
    case 'vegetables': return Icons.eco;
    case 'fruits': return Icons.apple;
    case 'smoking': return Icons.smoking_rooms;
    case 'health': return Icons.local_hospital;
    case 'entertainment': return Icons.movie;
    case 'education': return Icons.school;
    case 'vehicles': return Icons.directions_car;
    case 'home': return Icons.home;
    case 'personal_care': return Icons.face;
    case 'mobile_pc': return Icons.phone_android;
    case 'financial_commitments': return Icons.account_balance_wallet;
    case 'government_services': return Icons.account_balance;
    case 'gifts_occasions': return Icons.card_giftcard;
    case 'hobbies': return Icons.sports_soccer;
    case 'baby': return Icons.child_care;
    case 'clothes': return Icons.checkroom;
    case 'shoes': return Icons.hiking;
    default: return Icons.category;
  }
}

IconData getSubCategoryIcon() {
  return Icons.circle; // مؤقت للفئات الفرعية
}
