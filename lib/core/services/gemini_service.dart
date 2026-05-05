import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Service to analyze psychological + behavioral data via Gemini AI
class GeminiService {
  GeminiService({String? apiKey})
      : _apiKey = apiKey ?? '',
        _model = GenerativeModel(
          // `gemini-1.5-flash` is no longer valid on v1beta; use a current model id.
          model: 'gemini-2.0-flash',
          apiKey: apiKey ?? '',
        );


  final String _apiKey;
  final GenerativeModel _model;

  Future<Map<String, dynamic>> analyzeRisk({
    required Map<String, int> psychologicalScores,
    required Map<String, dynamic> behavioralMetrics,
  }) async {
    if (_apiKey.isEmpty) {
      return _fallbackAnalysis(psychologicalScores, behavioralMetrics);
    }

    try {
      final prompt = _buildPrompt(psychologicalScores, behavioralMetrics);
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      return _parseResponse(text, psychologicalScores, behavioralMetrics);
    } catch (e) {
      if (kDebugMode) debugPrint('Gemini API error: $e');
      return _fallbackAnalysis(psychologicalScores, behavioralMetrics);
    }
  }

  Future<String> generateGoalCheckIn({
    required List<Map<String, dynamic>> goals,
  }) async {
    if (goals.isEmpty) return '';

    if (_apiKey.isEmpty) {
      return _fallbackGoalCheckIn(goals);
    }

    try {
      final prompt = '''
أنت مساعد ذكي لتتبع الأهداف.
بناءً على أهداف المستخدم التالية، اكتب "رسالة متابعة قصيرة جدًا" بالعربية (سطر أو سطرين فقط) فيها:
- سؤال مباشر عن الإنجاز
- تحفيز بسيط
- الإشارة إلى الوقت/المدة المتبقية إن أمكن

لا تستخدم تنسيق Markdown ولا رموز طويلة.
لا تذكر أنك نموذج ذكاء اصطناعي.

البيانات:
${jsonEncode(goals)}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      if (text.isEmpty) return _fallbackGoalCheckIn(goals);
      return text;
    } catch (_) {
      return _fallbackGoalCheckIn(goals);
    }
  }

  String _buildPrompt(
    Map<String, int> psychologicalScores,
    Map<String, dynamic> behavioralMetrics,
  ) {
    return '''
أنت محلل صحة نفسية متخصص في الإدمان الرقمي. حلل البيانات التالية وقدم تقييماً:

الدرجات النفسية:
- القلق (GAD-2): ${psychologicalScores['anxiety'] ?? 0} من 6
- الاكتئاب (PHQ-2): ${psychologicalScores['depression'] ?? 0} من 6
- FoMO (الخوف من فوات الشيء): ${psychologicalScores['fomo'] ?? 0} من 20
- النوم (Epworth): ${psychologicalScores['sleep'] ?? 0} من 12

البيانات السلوكية:
- وقت الشاشة اليومي (دقائق): ${behavioralMetrics['total_screen_time'] ?? 0}
- استخدام ليلي: ${behavioralMetrics['night_usage'] ?? false}
- عدد فتحات القفل: ${behavioralMetrics['unlocks'] ?? 0}

أجب بصيغة JSON فقط بدون أي نص إضافي:
{
  "risk_level": "High" أو "Medium" أو "Low",
  "primary_factor": "العامل الرئيسي بالعربية",
  "recommendations": ["توصية 1", "توصية 2", "توصية 3"]
}
''';
  }

  Map<String, dynamic> _parseResponse(
    String text,
    Map<String, int> psychologicalScores,
    Map<String, dynamic> behavioralMetrics,
  ) {
    try {
      final jsonStr = text
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'\s*```'), '')
          .trim();
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return {
        'risk_level': map['risk_level'] ?? 'Medium',
        'primary_factor': map['primary_factor'] ?? 'غير محدد',
        'recommendations': (map['recommendations'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      };
    } catch (_) {
      return _fallbackAnalysis(psychologicalScores, behavioralMetrics);
    }
  }

  /// Generates a summary report from a list of previous assessments.
  /// Returns a readable report string (e.g. trend analysis, overall insights).
  Future<String> generateReportFromAssessments(
    List<Map<String, dynamic>> assessments, {
    String? periodLabelAr,
  }) async {
    if (assessments.isEmpty) {
      return 'لا توجد تقييمات سابقة لإنشاء التقرير.';
    }

    if (_apiKey.isEmpty) {
      return _fallbackReportFromAssessments(assessments);
    }

    try {
      final prompt = _buildReportPrompt(assessments, periodLabelAr: periodLabelAr);
      final response = await _model.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          maxOutputTokens: 8192,
          temperature: 0.65,
        ),
      );
      final text = response.text?.trim() ?? '';
      return text.isNotEmpty ? text : _fallbackReportFromAssessments(assessments);
    } catch (e) {
      if (kDebugMode) debugPrint('Gemini report error: $e');
      return _fallbackReportFromAssessments(assessments);
    }
  }

  String _buildReportPrompt(
    List<Map<String, dynamic>> assessments, {
    String? periodLabelAr,
  }) {
    final buffer = StringBuffer();
    if (periodLabelAr != null && periodLabelAr.isNotEmpty) {
      buffer.writeln('**الفترة المختارة للتقرير:** $periodLabelAr\n');
    }
    buffer.writeln(
      'أنت محلل صحة نفسية متخصص في الإدمان الرقمي والسلوك الرقمي. بناءً على سجل التقييمات التالي، اكتب تقريراً **مفصلاً وموسعاً** بالعربية.\n'
      '\n'
      '**مهم جداً — شكل المخرجات:**\n'
      'اكتب التقرير بصيغة **Markdown** فقط (بدون JSON). استخدم العناوين بالشكل التالي حرفياً:\n'
      '- `##` للعناوين الرئيسية (مستوى 2)\n'
      '- `###` للعناوين الفرعية داخل كل قسم\n'
      '- فقرات عادية بين العناوين، وقوائم نقطية بـ `-` لكل بند عند الحاجة\n'
      '- يمكن استخدام **نص غامق** للتأكيد داخل الفقرات\n'
      '- يمكنك وضع فاصل بين أقسام كبيرة بسطر يحتوي فقط: `---`\n'
      '\n'
      '**الهيكل الإلزامي للتقرير** (احترم الترتيب والعناوين بالشكل التالي):\n'
      '\n'
      '## ملخص تنفيذي\n'
      'فقرة أو فقرتان توضحان الصورة الكلية للمستخدم.\n'
      '\n'
      '## تحليل الاتجاهات عبر الزمن\n'
      'اربط التواريخ بالتغيّر؛ حدّد تحسناً أو ثباتاً أو تراجعاً، مع مؤشرات دعمت استنتاجك (درجات، مخاطر، وقت شاشة، استخدام ليلي، إلخ).\n'
      '\n'
      '## المحاور التفصيلية\n'
      '### القلق\n'
      '### الاكتئاب\n'
      '### جودة النوم\n'
      '### FoMO\n'
      '### السلوك الرقمي\n'
      'في كل فرع: تعليقات مبنية على البيانات وربطها ببعضها.\n'
      '\n'
      '## نقاط القوة\n'
      'قائمة نقطية بـ `-` لكل نقطة.\n'
      '\n'
      '## مجالات تحتاج عناية\n'
      'قائمة نقطية بـ `-` لكل نقطة.\n'
      '\n'
      '## توصيات عملية\n'
      'لا تكتفِ بثلاث نقاط؛ قدّم **8 فقرات نصائح على الأقل**. يمكنك تقسيمها بعناوين فرعية `###` أو قوائم. كل نصيحة محددة وقابلة للتطبيق. لغة داعمة لا مذمّمة.\n'
      '\n'
      '## خطة أسبوعية مقترحة\n'
      'جدول بسيط أو خطوات أيام يمكن البدء بها.\n'
      '\n'
      '## متى يُفضّل طلب دعم مهني\n'
      'علامات عامة، بدون تشخيص طبي.\n'
      '\n'
      '## تنويه\n'
      'اذكر أن التقرير تعليمي ولا يغني عن استشارة مختص عند الحاجة.\n'
      '\n',
    );
    for (var i = 0; i < assessments.length; i++) {
      final a = assessments[i];
      final date = a['date'];
      final dateStr = date != null ? '(تاريخ: $date)' : '';
      buffer.writeln('--- تقييم ${i + 1} $dateStr ---');
      buffer.writeln('الدرجات النفسية: ${a['psychological_scores'] ?? {}}');
      buffer.writeln('البيانات السلوكية: ${a['behavioral_metrics'] ?? {}}');
      buffer.writeln('نتيجة التحليل السابقة: ${a['ai_result'] ?? {}}');
      buffer.writeln();
    }
    buffer.writeln(
      'اكتب التقرير النهائي بالعربية فقط، بدون JSON، مع التزام كامل بهيكل Markdown والعناوين أعلاه. اكتب محتوى حقيقياً تحت كل عنوان (لا تنسخ جمل التعليمات حرفياً). كن مفصلاً: الهدف أن يخرج المستخدم بفهم أعمق وتقرير منظم وقابل للقراءة.',
    );
    return buffer.toString();
  }

  String _fallbackReportFromAssessments(List<Map<String, dynamic>> assessments) {
    final buffer = StringBuffer();
    buffer.writeln(
      'تقرير تلقائي (بدون اتصال بالذكاء الاصطناعي) بناءً على ${assessments.length} تقييم(ات) سابق(ة).\n',
    );
    var highCount = 0;
    var lowCount = 0;
    for (final a in assessments) {
      final ai = a['ai_result'] as Map<String, dynamic>? ?? {};
      final level = (ai['risk_level'] as String? ?? '').toLowerCase();
      if (level == 'high') highCount++;
      if (level == 'low') lowCount++;
    }
    buffer.writeln(
      '\n## ملخص تنفيذي\n'
      'هذا تقرير تلقائي بدون اتصال بالذكاء الاصطناعي؛ للتقرير المفصّل والمنظم فعّل مفتاح Gemini في التطبيق.\n'
      '\n## ملاحظات حول السجل\n'
      '- عدد التقييمات عالية المخاطر: $highCount\n'
      '- عدد التقييمات منخفضة المخاطر: $lowCount\n'
      '\n## توصيات عامة\n'
      '- جرّب تحديد ساعات «خالية من الهاتف» يومياً، وابدأ بفترة قصيرة ثم زِدها تدريجياً.\n'
      '- قلّل الإضاءة والإشعارات قبل النوم، وضع الجهاز خارج غرفة النوم إن أمكن.\n'
      '- راقب وقت الشاشة أسبوعياً ولاحظ أي ارتباط بين الأيام الصعبة وزيادة الاستخدام.\n'
      '- خصّص وقتاً لأنشطة بدون شاشة (مشي، قراءة ورقية، محادثة وجهاً لوجه).\n'
      '\n## متى يُفضّل طلب دعم مهني\n'
      'إذا تكررت المستويات العالية أو شعرت بضيق شديد، يُفضّل طلب دعم من مختص صحة نفسية.\n'
      '\n## تنويه\n'
      'لتحليل مفصّل ومنظم بالذكاء الاصطناعي، تأكد من ضبط مفتاح واجهة Gemini في التطبيق.',
    );
    return buffer.toString();
  }

  Map<String, dynamic> _fallbackAnalysis(
    Map<String, int> psychologicalScores,
    Map<String, dynamic> behavioralMetrics,
  ) {
    final anxiety = psychologicalScores['anxiety'] ?? 0;
    final depression = psychologicalScores['depression'] ?? 0;
    final fomo = psychologicalScores['fomo'] ?? 0;
    final sleep = psychologicalScores['sleep'] ?? 0;
    final screenTime = behavioralMetrics['total_screen_time'] as int? ?? 0;
    final nightUsage = behavioralMetrics['night_usage'] as bool? ?? false;

    int riskScore = 0;
    if (anxiety >= 4) {
      riskScore += 2;
    } else if (anxiety >= 2) {
      riskScore += 1;
    }
    if (depression >= 4) {
      riskScore += 2;
    } else if (depression >= 2) {
      riskScore += 1;
    }
    if (fomo >= 14) {
      riskScore += 2;
    } else if (fomo >= 10) {
      riskScore += 1;
    }
    if (sleep >= 5) {
      riskScore += 1;
    }
    if (screenTime >= 360) {
      riskScore += 2;
    } else if (screenTime >= 240) {
      riskScore += 1;
    }
    if (nightUsage) {
      riskScore += 1;
    }

    String riskLevel = 'Low';
    String primaryFactor = 'الوضع جيد بشكل عام';
    List<String> recommendations = [];

    if (riskScore >= 6) {
      riskLevel = 'High';
      primaryFactor = 'مستويات مرتفعة من القلق/الاكتئاب/FoMO مع استخدام مفرط';
      recommendations = [
        'حدد أوقاتاً خالية من الهاتف يومياً',
        'تجنب استخدام الهاتف قبل النوم بساعة على الأقل',
        'فكر في استشارة متخصص صحة نفسية',
        'مارس تمارين التنفس أو التأمل',
      ];
    } else if (riskScore >= 3) {
      riskLevel = 'Medium';
      primaryFactor = 'بعض العلامات تحتاج انتباهاً';
      recommendations = [
        'قلل وقت الشاشة تدريجياً',
        'حسّن عادات النوم',
        'خصص وقتاً للأنشطة دون شاشات',
      ];
    } else {
      recommendations = [
        'استمر في العادات الصحية',
        'راقب استخدامك بانتظام',
      ];
    }

    return {
      'risk_level': riskLevel,
      'primary_factor': primaryFactor,
      'recommendations': recommendations,
    };
  }

  String _fallbackGoalCheckIn(List<Map<String, dynamic>> goals) {
    final first = goals.first;
    final goal = first['text']?.toString().trim() ?? 'هدفك';
    final progress = (first['progressPercent'] as num?)?.toInt() ?? 0;
    return 'كيف تقدمك اليوم في "$goal"؟ نسبة إنجازك الحالية $progress% — خطوة بسيطة الآن تقربك كثيرًا من هدفك.';
  }
}
