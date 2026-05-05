import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/survey_type.dart';

class SurveyState {
  const SurveyState({
    this.currentIndex = 0,
    this.answers = const {},
  });

  final int currentIndex;
  final Map<SurveyType, List<int>> answers;

  SurveyType get currentSurvey => SurveyType.all[currentIndex];
  int get total => SurveyType.all.length;
  bool get isFirst => currentIndex == 0;
  bool get isLast => currentIndex == total - 1;
  double get progress => (currentIndex + 1) / total;

  int get currentQuestionIndex =>
      answers[currentSurvey]?.length ?? 0;

  bool get isCurrentSurveyComplete {
    final q = answers[currentSurvey] ?? [];
    return q.length >= currentSurvey.questions.length;
  }

  Map<String, int> get psychologicalScores {
    return {
      'anxiety': _sumAnswers(SurveyType.gad7),
      'depression': _sumAnswers(SurveyType.phq9),
      'fomo': _sumAnswers(SurveyType.fomo),
      'sleep': _sumAnswers(SurveyType.epworth),
    };
  }

  int _sumAnswers(SurveyType type) {
    final a = answers[type] ?? [];
    return a.fold(0, (s, v) => s + v);
  }

  SurveyState copyWith({
    int? currentIndex,
    Map<SurveyType, List<int>>? answers,
  }) {
    return SurveyState(
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
    );
  }
}

class SurveyNotifier extends StateNotifier<SurveyState> {
  SurveyNotifier() : super(const SurveyState());

  void next() {
    if (!state.isLast) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previous() {
    final qIndex = state.currentQuestionIndex;
    if (qIndex > 0) {
      final type = state.currentSurvey;
      final current = state.answers[type] ?? [];
      final updated = current.sublist(0, current.length - 1);
      state = state.copyWith(
        answers: {...state.answers, type: updated},
      );
    } else if (!state.isFirst) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void selectAnswer(int questionIndex, int score) {
    final type = state.currentSurvey;
    final current = state.answers[type] ?? [];
    final updated = [...current];

    if (questionIndex < updated.length) {
      updated[questionIndex] = score;
    } else {
      updated.add(score);
    }

    state = state.copyWith(
      answers: {...state.answers, type: updated},
    );
  }

  void reset() {
    state = const SurveyState();
  }
}

final surveyProvider = StateNotifierProvider<SurveyNotifier, SurveyState>((ref) {
  return SurveyNotifier();
});
