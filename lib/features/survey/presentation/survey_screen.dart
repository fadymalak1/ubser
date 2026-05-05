import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/presentation/dashboard_provider.dart';
import 'survey_provider.dart';

class SurveyScreen extends ConsumerStatefulWidget {
  const SurveyScreen({super.key});

  @override
  ConsumerState<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends ConsumerState<SurveyScreen>
    with TickerProviderStateMixin {
  int? _selectedOptionIndex;
  late AnimationController _questionAnimController;
  late Animation<double> _questionFade;
  late Animation<Offset> _questionSlide;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(surveyProvider.notifier).reset();
    });
    _questionAnimController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _questionFade = CurvedAnimation(
      parent: _questionAnimController,
      curve: Curves.easeOut,
    );
    _questionSlide = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _questionAnimController,
      curve: Curves.easeOut,
    ));
    _questionAnimController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = ref.read(surveyProvider);
    final displayQIndex = _displayQuestionIndex(state);
    if (displayQIndex >= 0) {
      final prev = state.answers[state.currentSurvey]?[displayQIndex];
      _selectedOptionIndex =
          prev != null ? _findOptionIndex(state, displayQIndex, prev) : null;
    } else {
      _selectedOptionIndex = null;
    }
  }

  int _displayQuestionIndex(SurveyState state) {
    final qIndex = state.currentQuestionIndex;
    final total = state.currentSurvey.questions.length;
    if (qIndex >= total) return total - 1;
    return qIndex;
  }

  int _findOptionIndex(SurveyState state, int qi, int score) {
    final q = state.currentSurvey.questions;
    if (qi >= q.length) return -1;
    final opts = q[qi].options;
    for (var i = 0; i < opts.length; i++) {
      if (opts[i].score == score) return i;
    }
    return -1;
  }

  void _onOptionSelected(int optionIndex) {
    setState(() => _selectedOptionIndex = optionIndex);
  }

  void _animateToNextQuestion() {
    _questionAnimController.reset();
    _questionAnimController.forward();
  }

  Future<void> _submitAndShowResult(SurveyState newState) async {
    final result = await ref
        .read(dashboardProvider.notifier)
        .saveAssessmentFromSurvey(newState);
    if (!mounted) return;
    if (result != null) {
      ref.read(testResultPendingProvider.notifier).state = result;
      context.go(AppRoutes.testResult);
    } else {
      context.go(AppRoutes.dashboard);
    }
  }

  void _onNext() {
    final state = ref.read(surveyProvider);
    final notifier = ref.read(surveyProvider.notifier);
    final displayQIndex = _displayQuestionIndex(state);
    final questions = state.currentSurvey.questions;

    if (_selectedOptionIndex == null && displayQIndex < questions.length) return;

    if (displayQIndex < questions.length) {
      final score =
          questions[displayQIndex].options[_selectedOptionIndex!].score;
      notifier.selectAnswer(displayQIndex, score);
      setState(() => _selectedOptionIndex = null);
    }

    final newState = ref.read(surveyProvider);
    if (newState.currentQuestionIndex >= newState.currentSurvey.questions.length) {
      if (newState.isLast) {
        _submitAndShowResult(newState);
        return;
      } else {
        notifier.next();
        setState(() => _selectedOptionIndex = null);
        _animateToNextQuestion();
      }
    } else {
      _animateToNextQuestion();
    }
  }

  @override
  void dispose() {
    _questionAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surveyState = ref.watch(surveyProvider);
    final surveyNotifier = ref.read(surveyProvider.notifier);
    final displayQIndex = _displayQuestionIndex(surveyState);
    final survey = surveyState.currentSurvey;
    final questions = survey.questions;
    final totalQuestions = questions.length;
    final surveyProgress = (displayQIndex + 1) / totalQuestions;

    if (displayQIndex < 0) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = questions[displayQIndex];
    final isLastQuestion = displayQIndex + 1 >= totalQuestions;
    final isVeryLast = isLastQuestion && surveyState.isLast;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top bar with back/close and survey info ───────────────────
            _SurveyTopBar(
              surveyState: surveyState,
              displayQIndex: displayQIndex,
              totalQuestions: totalQuestions,
              surveyProgress: surveyProgress,
              onBack: () {
                if (surveyState.isFirst && displayQIndex == 0) {
                  context.go('/dashboard');
                } else {
                  surveyNotifier.previous();
                  setState(() => _selectedOptionIndex = null);
                  _animateToNextQuestion();
                }
              },
              isClose: surveyState.isFirst && displayQIndex == 0,
            ),

            // ── Question content ──────────────────────────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _questionFade,
                child: SlideTransition(
                  position: _questionSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Question card
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Survey type pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                survey.subtitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Question number badge + text
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryPaleColor(context),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${displayQIndex + 1}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    question.text,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          height: 1.45,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Options list
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          itemCount: question.options.length,
                          itemBuilder: (context, i) {
                            final opt = question.options[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _OptionCard(
                                label: opt.text,
                                index: i,
                                isSelected: _selectedOptionIndex == i,
                                onTap: () => _onOptionSelected(i),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Next button ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: _selectedOptionIndex != null
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppTheme.buttonShadow,
                      )
                    : null,
                child: FilledButton.icon(
                  onPressed: _selectedOptionIndex != null ? _onNext : null,
                  icon: Icon(
                    isVeryLast
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    isVeryLast ? 'إنهاء التقييم' : 'التالي',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Survey Top Bar ────────────────────────────────────────────────────────────

class _SurveyTopBar extends StatelessWidget {
  const _SurveyTopBar({
    required this.surveyState,
    required this.displayQIndex,
    required this.totalQuestions,
    required this.surveyProgress,
    required this.onBack,
    required this.isClose,
  });

  final SurveyState surveyState;
  final int displayQIndex;
  final int totalQuestions;
  final double surveyProgress;
  final VoidCallback onBack;
  final bool isClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceColor(context),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.lg, 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back/close button
              Material(
                color: AppTheme.primaryPaleColor(context),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      isClose
                          ? Icons.close_rounded
                          : Icons.arrow_back_ios_new_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surveyState.currentSurvey.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'استبيان ${surveyState.currentIndex + 1} من ${surveyState.total}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor(context),
                          ),
                    ),
                  ],
                ),
              ),
              // Question counter chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPaleColor(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${displayQIndex + 1} / $totalQuestions',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Segmented progress dots
          _SegmentedProgress(
            total: totalQuestions,
            completed: displayQIndex + 1,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({
    required this.total,
    required this.completed,
  });

  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final done = i < completed;
        final isCurrent = i == completed - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 3 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 5,
              decoration: BoxDecoration(
                gradient: done
                    ? (isCurrent
                        ? AppTheme.primaryGradient
                        : const LinearGradient(
                            colors: [AppTheme.primaryTealLight, AppTheme.primaryTeal],
                          ))
                    : null,
                color: done ? null : AppTheme.borderColorFor(context),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Option Card ───────────────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : AppTheme.borderColorFor(context),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Letter indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? null
                    : Border.all(color: AppTheme.borderColorFor(context)),
              ),
              child: Center(
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : Text(
                        String.fromCharCode(0x0041 + index),
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : AppTheme.textPrimaryColor(context),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
