import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../services/fcm_service.dart';

/// Auth state
enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.email,
    this.name,
    this.ageGroup,
    this.isLoading = false,
  });

  final AuthStatus status;
  final String? userId;
  final String? email;
  final String? name;
  final String? ageGroup;
  final bool isLoading;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> checkAuth() async {
    final user = _auth.currentUser;
    if (user == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        state = AuthState(
          status: AuthStatus.authenticated,
          userId: user.uid,
          email: user.email,
          name: data['name'] as String?,
          ageGroup: data['age_group'] as String?,
        );
      } else {
        state = AuthState(
          status: AuthStatus.authenticated,
          userId: user.uid,
          email: user.email,
        );
      }
      // Save / refresh FCM token whenever auth state is confirmed
      await FcmService.instance.saveTokenForUser(user.uid);
    } catch (_) {
      state = AuthState(
        status: AuthStatus.authenticated,
        userId: user.uid,
        email: user.email,
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await checkAuth();
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String ageGroup,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(cred.user!.uid)
            .set({
          'uid': cred.user!.uid,
          'email': email,
          'name': name,
          'age_group': ageGroup,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      await checkAuth();
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Updates the current user's password. Requires current password for reauth.
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';
    if (user.email == null || user.email!.isEmpty) {
      throw 'لا يمكن تغيير كلمة المرور بدون بريد إلكتروني';
    }

    state = state.copyWith(isLoading: true);
    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'invalid-email':
        return 'بريد إلكتروني غير صالح';
      case 'weak-password':
        return 'كلمة المرور ضعيفة';
      case 'requires-recent-login':
        return 'يجب تسجيل الدخول مرة أخرى لتغيير كلمة المرور';
      default:
        return 'حدث خطأ في المصادقة';
    }
  }
}

extension _AuthStateCopyWith on AuthState {
  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? email,
    String? name,
    String? ageGroup,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      ageGroup: ageGroup ?? this.ageGroup,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
