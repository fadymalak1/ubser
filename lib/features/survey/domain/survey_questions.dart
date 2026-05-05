/// Survey question model
class SurveyQuestion {
  const SurveyQuestion({
    required this.text,
    required this.options,
  });

  final String text;
  final List<SurveyOption> options;
}

class SurveyOption {
  const SurveyOption({
    required this.text,
    required this.score,
  });

  final String text;
  final int score;
}

/// GAD (مختصر) - 5 أسئلة، 0-3 لكل سؤال
const List<SurveyQuestion> gad7Questions = [
  SurveyQuestion(
    text: 'الشعور بالتوتر أو القلق أو العصبية',
    options: [
      SurveyOption(text: 'لا أبداً', score: 0),
      SurveyOption(text: 'عدة أيام', score: 1),
      SurveyOption(text: 'أكثر من نصف الأيام', score: 2),
      SurveyOption(text: 'تقريباً كل يوم', score: 3),
    ],
  ),
  SurveyQuestion(
    text: 'عدم القدرة على إيقاف أو التحكم في القلق',
    options: [
      SurveyOption(text: 'لا أبداً', score: 0),
      SurveyOption(text: 'عدة أيام', score: 1),
      SurveyOption(text: 'أكثر من نصف الأيام', score: 2),
      SurveyOption(text: 'تقريباً كل يوم', score: 3),
    ],
  ),
  SurveyQuestion(
    text: 'القلق المفرط بشأن أمور مختلفة',
    options: [
      SurveyOption(text: 'لا أبداً', score: 0),
      SurveyOption(text: 'عدة أيام', score: 1),
      SurveyOption(text: 'أكثر من نصف الأيام', score: 2),
      SurveyOption(text: 'تقريباً كل يوم', score: 3),
    ],
  ),
  SurveyQuestion(
    text: 'صعوبة الاسترخاء',
    options: [
      SurveyOption(text: 'لا أبداً', score: 0),
      SurveyOption(text: 'عدة أيام', score: 1),
      SurveyOption(text: 'أكثر من نصف الأيام', score: 2),
      SurveyOption(text: 'تقريباً كل يوم', score: 3),
    ],
  ),
  SurveyQuestion(
    text: 'أشعر بقلق شديد لدرجة يصعب معها الجلوس ساكنًا',
    options: [
      SurveyOption(text: 'لا أبداً', score: 0),
      SurveyOption(text: 'عدة أيام', score: 1),
      SurveyOption(text: 'أكثر من نصف الأيام', score: 2),
      SurveyOption(text: 'تقريباً كل يوم', score: 3),
    ],
  ),
];

/// PHQ (مختصر) - 5 أسئلة، 0-3 لكل سؤال
const List<SurveyQuestion> phq9Questions = [
  SurveyQuestion(
    text: 'قلة الاهتمام أو المتعة في فعل الأشياء',
    options: [
      SurveyOption(text: 'لا أبداً', score: 0),
      SurveyOption(text: 'عدة أيام', score: 1),
      SurveyOption(text: 'أكثر من نصف الأيام', score: 2),
      SurveyOption(text: 'تقريباً كل يوم', score: 3),
    ],
  ),
  SurveyQuestion(
    text: 'الشعور بالحزن أو الاكتئاب أو اليأس',
    options: [
      SurveyOption(text: 'لا أبداً', score: 0),
      SurveyOption(text: 'عدة أيام', score: 1),
      SurveyOption(text: 'أكثر من نصف الأيام', score: 2),
      SurveyOption(text: 'تقريباً كل يوم', score: 3),
    ],
  ),
  SurveyQuestion(
    text: 'صعوبات في النوم، أو الاستمرار في النوم، أو النوم لفترات طويلة جدًا',
    options: [
      SurveyOption(text: 'لا أبداً', score: 0),
      SurveyOption(text: 'عدة أيام', score: 1),
      SurveyOption(text: 'أكثر من نصف الأيام', score: 2),
      SurveyOption(text: 'تقريباً كل يوم', score: 3),
    ],
  ),
  SurveyQuestion(
    text: 'الشعور بالتعب أو قلة الطاقة',
    options: [
      SurveyOption(text: 'لا أبداً', score: 0),
      SurveyOption(text: 'عدة أيام', score: 1),
      SurveyOption(text: 'أكثر من نصف الأيام', score: 2),
      SurveyOption(text: 'تقريباً كل يوم', score: 3),
    ],
  ),
  SurveyQuestion(
    text: 'ضعف الشهية أو الإفراط في تناول الطعام',
    options: [
      SurveyOption(text: 'لا أبداً', score: 0),
      SurveyOption(text: 'عدة أيام', score: 1),
      SurveyOption(text: 'أكثر من نصف الأيام', score: 2),
      SurveyOption(text: 'تقريباً كل يوم', score: 3),
    ],
  ),
];

/// FoMO - الخوف من فوات الشيء (5 أسئلة، 1-5)
const List<SurveyQuestion> fomoQuestions = [
  SurveyQuestion(
    text: 'أشعر بأني أخشى أن يفوتني شيء ممتع أو ممتع جدًا',
    options: [
      SurveyOption(text: 'لا ينطبق علي أبداً', score: 1),
      SurveyOption(text: 'ينطبق قليلاً', score: 2),
      SurveyOption(text: 'ينطبق بشكل متوسط', score: 3),
      SurveyOption(text: 'ينطبق بشكل كبير', score: 4),
      SurveyOption(text: 'ينطبق علي تماماً', score: 5),
    ],
  ),
  SurveyQuestion(
    text: 'أشعر بالقلق من أن الآخرين قد تكون لديهم تجارب أفضل مني',
    options: [
      SurveyOption(text: 'لا ينطبق علي أبداً', score: 1),
      SurveyOption(text: 'ينطبق قليلاً', score: 2),
      SurveyOption(text: 'ينطبق بشكل متوسط', score: 3),
      SurveyOption(text: 'ينطبق بشكل كبير', score: 4),
      SurveyOption(text: 'ينطبق علي تماماً', score: 5),
    ],
  ),
  SurveyQuestion(
    text: 'أشعر بالحاجة المستمرة لمعرفة ما يفعله الآخرون',
    options: [
      SurveyOption(text: 'لا ينطبق علي أبداً', score: 1),
      SurveyOption(text: 'ينطبق قليلاً', score: 2),
      SurveyOption(text: 'ينطبق بشكل متوسط', score: 3),
      SurveyOption(text: 'ينطبق بشكل كبير', score: 4),
      SurveyOption(text: 'ينطبق علي تماماً', score: 5),
    ],
  ),
  SurveyQuestion(
    text: 'عندما لا أكون متاحًا عبر الإنترنت، أشعر أنني قد أفوت شيئًا مهمًا',
    options: [
      SurveyOption(text: 'لا ينطبق علي أبداً', score: 1),
      SurveyOption(text: 'ينطبق قليلاً', score: 2),
      SurveyOption(text: 'ينطبق بشكل متوسط', score: 3),
      SurveyOption(text: 'ينطبق بشكل كبير', score: 4),
      SurveyOption(text: 'ينطبق علي تماماً', score: 5),
    ],
  ),
  SurveyQuestion(
    text: 'أشعر بالحزن عندما أسمع أن الآخرين قاموا بشيء ممتع ولم أكن هناك',
    options: [
      SurveyOption(text: 'لا ينطبق علي أبداً', score: 1),
      SurveyOption(text: 'ينطبق قليلاً', score: 2),
      SurveyOption(text: 'ينطبق بشكل متوسط', score: 3),
      SurveyOption(text: 'ينطبق بشكل كبير', score: 4),
      SurveyOption(text: 'ينطبق علي تماماً', score: 5),
    ],
  ),
];

/// جودة النوم - 5 أسئلة، 0-3 لكل سؤال
const List<SurveyQuestion> epworthQuestions = [
  SurveyQuestion(
    text: 'أنام نومًا هادئًا ومريحًا',
    options: [
      SurveyOption(text: 'تقريباً كل يوم', score: 0),
      SurveyOption(text: 'أكثر من نصف الأيام', score: 1),
      SurveyOption(text: 'عدة أيام', score: 2),
      SurveyOption(text: 'لا أبداً', score: 3),
    ],
  ),
  SurveyQuestion(
    text: 'أجد صعوبة في النوم عند الذهاب للفراش',
    options: [
      SurveyOption(text: 'لا أبداً', score: 0),
      SurveyOption(text: 'عدة أيام', score: 1),
      SurveyOption(text: 'أكثر من نصف الأيام', score: 2),
      SurveyOption(text: 'تقريباً كل يوم', score: 3),
    ],
  ),
  SurveyQuestion(
    text: 'أستغرق وقتًا طويلًا للوصول إلى النوم (أكثر من 30 دقيقة)',
    options: [
      SurveyOption(text: 'لا أبداً', score: 0),
      SurveyOption(text: 'عدة أيام', score: 1),
      SurveyOption(text: 'أكثر من نصف الأيام', score: 2),
      SurveyOption(text: 'تقريباً كل يوم', score: 3),
    ],
  ),
  SurveyQuestion(
    text: 'أستيقظ عدة مرات أثناء الليل أو أجد صعوبة في العودة للنوم',
    options: [
      SurveyOption(text: 'لا أبداً', score: 0),
      SurveyOption(text: 'عدة أيام', score: 1),
      SurveyOption(text: 'أكثر من نصف الأيام', score: 2),
      SurveyOption(text: 'تقريباً كل يوم', score: 3),
    ],
  ),
  SurveyQuestion(
    text: 'أشعر بالتعب أو النعاس خلال النهار',
    options: [
      SurveyOption(text: 'لا أبداً', score: 0),
      SurveyOption(text: 'عدة أيام', score: 1),
      SurveyOption(text: 'أكثر من نصف الأيام', score: 2),
      SurveyOption(text: 'تقريباً كل يوم', score: 3),
    ],
  ),
];
