/// Form validation utilities - reusable across the app
class Validators {
  Validators._();

  static String? required(String? value, [String message = 'هذا الحقل مطلوب']) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'أدخل البريد الإلكتروني';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'بريد إلكتروني غير صالح';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) return 'أدخل كلمة المرور';
    if (value.length < minLength) {
      return 'كلمة المرور يجب أن تكون $minLength أحرف على الأقل';
    }
    return null;
  }

  static String? dropdown<T>(T? value, [String message = 'اختر قيمة']) {
    return value == null ? message : null;
  }
}
