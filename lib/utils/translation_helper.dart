import '../l10n/app_localizations.dart';

extension CategoryTranslation on AppLocalizations {
  String tr(String key) {
    switch (key) {

      /// 🟦 Main Categories
      case 'transport': return transport;
      case 'bills': return bills;
      case 'supermarket': return supermarket;
      case 'eat_out': return eatOut;
      case 'meat_fish': return meatFish;
      case 'vegetables': return vegetables;
      case 'fruits': return fruits;
      case 'smoking': return smoking;
      case 'health': return health;
      case 'entertainment': return entertainment;
      case 'education': return education;
      case 'vehicles': return vehicles;
      case 'home': return home;
      case 'personal_care': return personalCare;
      case 'mobile_pc': return mobilePc;
      case 'financial_commitments': return financialCommitments;
      case 'government_services': return governmentServices;
      case 'gifts_occasions': return giftsOccasions;
      case 'hobbies': return hobbies;
      case 'baby': return baby;
      case 'clothes': return clothes;
      case 'shoes': return shoes;

      ///  Sub Categories (Transport sample)
      case 'tuktuk': return tuktuk;
      case 'microbus': return microbus;
      case 'taxi_uber': return taxiUber;
      case 'bus': return bus;
      case 'metro': return metro;
      case 'train': return train;

      default:
        return key;
    }
  }
}
