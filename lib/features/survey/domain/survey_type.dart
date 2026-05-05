import 'survey_questions.dart';

/// Survey types: GAD/PHQ/FoMO/Sleep (5 أسئلة لكل استبيان)
enum SurveyType {
  gad7('GAD (مختصر)', 'قياس القلق', gad7Questions),
  phq9('PHQ (مختصر)', 'قياس الاكتئاب', phq9Questions),
  fomo('FoMO', 'الخوف من فوات الشيء', fomoQuestions),
  epworth('Sleep', 'جودة النوم', epworthQuestions);

  const SurveyType(this.title, this.subtitle, this.questions);
  final String title;
  final String subtitle;
  final List<SurveyQuestion> questions;

  static List<SurveyType> get all => values;
}
