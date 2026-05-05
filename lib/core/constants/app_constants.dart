/// Application-wide constants for UBSER
class AppConstants {
  AppConstants._();

  static const String appLogoPath = 'assets/logo/logo.png';
  static const String appWhiteLogoPath = 'assets/logo/logo_white.png';
  static const String appName = 'UBSER';
  static const String appNameAr = 'أبصر';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String assessmentsCollection = 'assessments';
  static const String feedbackCollection = 'feedback';

  // Risk levels (English for API/Firestore, Arabic for display)
  static const String riskLow = 'Low';
  static const String riskMedium = 'Medium';
  static const String riskHigh = 'High';

  static String riskLevelAr(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return 'منخفض';
      case 'medium':
        return 'متوسط';
      case 'high':
        return 'عالي';
      default:
        return level;
    }
  }

  // Age groups
  static const List<String> ageGroups = [
    '18-24',
    '25-34',
    '35-44',
    '45-54',
    '55+',
  ];
}
