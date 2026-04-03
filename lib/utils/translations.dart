import 'package:flutter/material.dart';

extension StringTranslate on BuildContext {
  String tr(String key) {
    final Map<String, String> ar = {
      "expenses": "المصروفات",
      "analysis": "تحليل",
      "totalExpenses": "إجمالي المصروفات",
      "realExpenses": "المصروفات العادية",
      "exceptionalExpenses": "المصروفات الاستثنائية",
      "vsLastPeriod": "% مقابل الفترة السابقة",
      "deleteCategory": "حذف هذه الفئة",
      "delete": "حذف",
      "cancel": "إلغاء",
      "subCategories": "التصنيفات الفرعية",
      "dailyTransport": "مواصلات يومية",
      "bills": "فواتير",
      "supermarket": "سوبر ماركت",
      "drinks": "مشروبات",
      "fastFood": "أكل بره",
      "meatFish": "لحوم وأسماك",
      "vegetables": "خضروات",
      "fruits": "فاكهة",
      "smoking": "تدخين",
      "health": "صحة",
      "entertainment": "ترفيه",
      "education": "تعليم",
      "vehicles": "مركبات",
      "home": "المنزل",
      "personalCare": "عناية شخصية",
      "mobilePc": "موبايل وكمبيوتر",
      "financials": "التزامات مالية",
      "governServices": "خدمات حكومية",
      "giftsOccasions": "هدايا ومناسبات",
      "hobbies": "هوايات",
      "baby": "بيبي",
      "clothes": "ملابس",
      "shoes": "أحذية"
    };
    
    final Map<String, String> en = {
      "expenses": "Expenses",
      "analysis": "Analysis",
      "totalExpenses": "Total Expenses",
      "realExpenses": "Real Expenses",
      "exceptionalExpenses": "Exceptional Expenses",
      "vsLastPeriod": "% Vs last period",
      "deleteCategory": "Delete this category?",
      "delete": "Delete",
      "cancel": "Cancel",
      "subCategories": "Sub Categories",
      "dailyTransport": "Daily Transport",
      "bills": "Bills",
      "supermarket": "Supermarket",
      "drinks": "Drinks",
      "fastFood": "Fast Food",
      "meatFish": "Meat & Fish",
      "vegetables": "Vegetables",
      "fruits": "Fruits",
      "smoking": "Smoking",
      "health": "Health",
      "entertainment": "Entertainment",
      "education": "Education",
      "vehicles": "Vehicles",
      "home": "Home",
      "personalCare": "Personal Care",
      "mobilePc": "Mobile & PC",
      "financials": "Financials",
      "governServices": "Govern. Services",
      "giftsOccasions": "Gifts & Occasions",
      "hobbies": "Hobbies",
      "baby": "Baby",
      "clothes": "Clothes",
      "shoes": "Shoes"
    };
    
    final locale = Localizations.localeOf(this).languageCode;
    final map = locale == "ar" ? ar : en;
    return map[key] ?? key;
  }
}
