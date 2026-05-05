# UBSER (أبصر)

تطبيق ذكي يساعد المستخدمين على رؤية سلوكهم الرقمي بوضوح وقياس خطر الإدمان الرقمي.

## التقنيات

- **Frontend:** Flutter (Android & iOS)
- **Backend:** Firebase (Auth, Firestore)
- **AI:** Google Gemini API (مع نظام احتياطي قائم على القواعد)
- **تتبع الاستخدام:** app_usage (Android)

## الإعداد

### 1. تثبيت التبعيات

```bash
flutter pub get
```

### 2. إعداد Firebase

1. أنشئ مشروعاً في [Firebase Console](https://console.firebase.google.com)
2. فعّل Authentication (البريد/كلمة المرور) و Firestore
3. قم بتشغيل:

```bash
dart run flutterfire_cli:flutterfire configure
```

4. انشر فهارس Firestore (للتقارير):

```bash
firebase deploy --only firestore:indexes
```

### 3. مفتاح Gemini API (اختياري)

للحصول على توصيات مخصصة من الذكاء الاصطناعي، أضف مفتاح Gemini:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
```

بدون المفتاح، يعمل التطبيق بنظام قواعد احتياطي لتحديد مستوى الخطر.

### 4. تشغيل التطبيق

```bash
flutter run
```

## الميزات المنفذة

- ✅ **التسجيل والدخول** عبر Firebase Auth
- ✅ **التقييم النفسي** (GAD-7, PHQ-9, FoMO, Epworth, ASRS)
- ✅ **تتبع السلوك** (وقت الشاشة على Android)
- ✅ **تحليل المخاطر** (Gemini AI أو قواعد ثابتة)
- ✅ **لوحة التحكم** مع مستوى الخطر والتوصيات
- ✅ **التقارير** الأسبوعية/الشهرية
- ✅ **تصميم حديث** بألوان Teal

## هيكل المشروع

```
lib/
├── core/
│   ├── constants/
│   ├── providers/        # Auth
│   ├── router/
│   ├── services/        # Assessment, Gemini
│   ├── theme/           # Teal theme
│   └── firebase/
├── features/
│   ├── auth/            # Login, Register
│   ├── dashboard/       # لوحة التحكم + التوصيات
│   ├── reports/         # التقارير
│   ├── splash/
│   └── survey/          # الاستبيانات النفسية
└── shared/widgets/
```

## قاعدة البيانات (Firestore)

- **users:** الملف الشخصي (uid, email, name, age_group)
- **assessments:** نتائج التقييم (psychological_scores, behavioral_metrics, ai_result)
- **feedback:** تقييمات المستخدمين (مستقبلي)
