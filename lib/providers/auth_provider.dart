import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/helpers/utils/sec_storage.dart';
import '../helpers/utils/init_appwrite.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  late String _error;
  late User _user;

  String get error => _error;
  User get user => _user;

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
      return false;
    }
  }

  //
}
