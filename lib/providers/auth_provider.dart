import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/consts.dart';
import 'package:fplwordle/helpers/utils/sec_storage.dart';
import '../helpers/utils/init_appwrite.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  late String _error;
  User? _user;
  int _otpResendCountdown = 0;

  String get error => _error;
  User? get user => _user;
  int get otpResendCountdown => _otpResendCountdown;

  // check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    String? res = await secStorage.read(key: 'onboarding');
    if (res == null || res != 'complete') {
      return false;
    } else {
      return true;
    }
  }

  // complete onboarding
  Future<void> completeOnboarding() async {
    await secStorage.write(key: "onboarding", value: "complete");
  }

  // check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final res = await account.get();
      _user = User.fromJson(res.toMap());

      return true;
    } on AppwriteException catch (e) {
      _error = e.message!;
      debugPrint(_error);
      return false;
    }
  }

  // sign up user
  Future<bool> emailAccountRegistration({required String email, required String password, required String name}) async {
    try {
      await account.create(userId: ID.unique(), email: email, password: password, name: name);

      return true;
    } on AppwriteException catch (e) {
      _error = e.message!;
      debugPrint(_error);
      return false;
    }
  }

  // sign in user
  Future<bool> emailSignIn({required String email, required String password}) async {
    try {
      await account.createEmailSession(email: email, password: password);

      return true;
    } on AppwriteException catch (e) {
      _error = e.message!;
      debugPrint(_error);
      return false;
    }
  }

  // google authentification
  Future<bool> googleAuth() async {
    try {
      await account.createOAuth2Session(
        provider: 'google',
        success: "http://localhost:62541/auth.html",
      );

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint(_error);
      return false;
    }
  }

  // otp resend btn countdown timer
  void startOtpResendCountdown() {
    _otpResendCountdown = 60;
    notifyListeners();
    Future.delayed(const Duration(seconds: 1), () {
      _otpResendCountdown--;
      notifyListeners();
      if (_otpResendCountdown > 0) {
        startOtpResendCountdown();
      }
    });
  }

  // execute email verification OTP sender function
  Future<String?> sendOTP({required String email, required String name}) async {
    Map<String, dynamic> data = {
      'email': email,
      'name': name,
    };
    String payload = jsonEncode(data);

    try {
      final res = await functions.createExecution(
        functionId: Consts.otpSender,
        data: payload,
      );

      String responseString = res.response;
      Map<String, dynamic> response = jsonDecode(responseString);

      if (response['status'] == 'success') {
        // save time of OTP generation
        String now = DateTime.now().millisecondsSinceEpoch.toString();
        await secStorage.write(key: 'otp_time', value: now);

        // save and return OTP
        String otp = response['otp'].toString();
        await secStorage.write(key: 'otp', value: otp);

        // start countdown timer
        startOtpResendCountdown();

        return response['otp'].toString();
      } else {
        _error = response['message'];
        return null;
      }
    } on AppwriteException catch (e) {
      _error = e.message!;
      debugPrint(_error);
      return null;
    }
  }

  // verify OTP
  Future<bool> verifyOTP(String otp) async {
    // get otp, time of OTP generation and current time
    String otpStored = (await secStorage.read(key: 'otp'))!;
    String otpTime = (await secStorage.read(key: 'otp_time'))!;
    int otpTimeInt = int.parse(otpTime);
    int now = DateTime.now().millisecondsSinceEpoch;

    // check if OTP is expired
    if (now - otpTimeInt > 300000) {
      _error = 'OTP expired';
      return false;
    }

    // check if OTP is valid
    if (otp != otpStored) {
      _error = 'Invalid OTP';
      return false;
    }

    return true;
  }

  // execute email verification function
  Future<bool> verifyEmail() async {
    Map<String, dynamic> data = {
      'userId': _user!.id,
    };
    String payload = jsonEncode(data);

    try {
      final res = await functions.createExecution(
        functionId: Consts.emailVerifier,
        data: payload,
      );

      String responseString = res.response;
      Map<String, dynamic> response = jsonDecode(responseString);

      if (response['status'] == 'success') {
        return true;
      } else {
        _error = response['message'];
        return false;
      }
    } on AppwriteException catch (e) {
      _error = e.message!;
      debugPrint(_error);
      return false;
    }
  }

  // sign out user
  Future<void> signOut() async {
    await account.deleteSession(sessionId: 'current');
  }
}
