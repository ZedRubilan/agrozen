import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

class AuthRepository {
  final SupabaseClient? _customClient;

  AuthRepository({SupabaseClient? client}) : _customClient = client;

  bool get _isReady => _customClient != null || SupabaseConfig.isConfigured;

  SupabaseClient get _client => _customClient ?? SupabaseConfig.client;

  User? get currentUser => _isReady ? _client.auth.currentUser : null;

  Session? get currentSession => _isReady ? _client.auth.currentSession : null;

  bool get isAuthenticated => currentUser != null;

  String? get currentUserId => currentUser?.id;

  Stream<AuthState> get authStateChanges =>
      _isReady ? _client.auth.onAuthStateChange : const Stream.empty();

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception('Failed to sign up: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during registration: $e');
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception('Failed to sign in: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during sign in: $e');
    }
  }

  /// Send OTP code to phone number
  Future<void> signInWithOtp({required String phone}) async {
    try {
      await _client.auth.signInWithOtp(
        phone: phone,
      );
    } on AuthException catch (e) {
      throw Exception('Failed to send OTP to $phone: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error sending OTP: $e');
    }
  }

  /// Verify OTP code sent to phone number
  Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception('Invalid verification code: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error verifying code: $e');
    }
  }

  /// Sign out current session
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Failed to sign out: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during sign out: $e');
    }
  }
}
