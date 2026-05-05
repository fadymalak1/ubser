import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedAgeGroup;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    );

    // Header fades in quickly
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Card slides up with a gentle deceleration
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Card scales from 96% → 100% for a "lift" feel
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAgeGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar( 
        
          content: const Text('الرجاء اختيار الفئة العمرية'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
      return;
    }

    try {
      await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            ageGroup: _selectedAgeGroup!,
          );
      if (!mounted) return;
      context.go(AppRoutes.survey);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: Stack(
        children: [
          // Top gradient header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 180,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.splashGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
            ),
          ),

          // Form
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: ScaleTransition(
                          scale: _scaleAnim,
                          child: AppCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Header with logo
                                  Row(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.primaryGradient,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.asset(
                                            AppConstants.appWhiteLogoPath,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.visibility,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'مرحباً بك!',
                                            style: Theme.of(context).textTheme.headlineSmall
                                                ?.copyWith(fontWeight: FontWeight.w800),
                                          ),
                                          Text(
                                            'أنشئ حسابك لتبدأ رحلتك',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xl),

                                  // Fields
                                  AppTextField(
                                    controller: _nameController,
                                    labelText: 'الاسم الكامل',
                                    hintText: 'أدخل اسمك',
                                    prefixIcon: const Icon(Icons.person_outlined),
                                    validator: (v) => Validators.required(v, 'أدخل الاسم'),
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  AppTextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    labelText: 'البريد الإلكتروني',
                                    hintText: 'example@email.com',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    validator: Validators.email,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  AppDropdown<String>(
                                    value: _selectedAgeGroup,
                                    labelText: 'الفئة العمرية',
                                    prefixIcon: const Icon(Icons.cake_outlined),
                                    items: AppConstants.ageGroups
                                        .map((age) => DropdownMenuItem(
                                              value: age,
                                              child: Text(age),
                                            ))
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => _selectedAgeGroup = value),
                                    validator: (v) =>
                                        Validators.dropdown(v, 'اختر الفئة العمرية'),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  AppPasswordField(
                                    controller: _passwordController,
                                    validator: (v) => Validators.password(v),
                                    textInputAction: TextInputAction.done,
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  AppLoadingButton(
                                    onPressed: _handleRegister,
                                    label: 'إنشاء الحساب',
                                    isLoading: authState.isLoading,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'لديك حساب بالفعل؟  ',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      GestureDetector(
                                        onTap: () => context.go(AppRoutes.login),
                                        child: Text(
                                          'تسجيل الدخول',
                                          style: TextStyle(
                                            color: AppTheme.primaryTeal,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // Back button — must be last in Stack to stay on top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Material(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.go(AppRoutes.login),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Text(
                      'إنشاء حساب جديد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
