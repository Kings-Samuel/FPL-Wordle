import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/providers/auth_provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';

Future<void> initOnesignal(BuildContext context) async {
  if (!kIsWeb) {
  OneSignal.shared.setAppId("00dad42c-2c25-491b-8cc4-e25b843a3d24");
  OneSignal.shared.promptUserForPushNotificationPermission();
  OneSignal.shared.setNotificationWillShowInForegroundHandler((OSNotificationReceivedEvent event) {
    event.complete(event.notification);
  });
  OneSignal.shared.setNotificationOpenedHandler((OSNotificationOpenedResult result) {
    // Will be called whenever a notification is opened/button pressed.
  });
  OneSignal.shared.setPermissionObserver((OSPermissionStateChanges changes) {
    // Will be called whenever the permission changes
    // (ie. user taps Allow on the permission prompt in iOS)
  });
  OneSignal.shared.setSubscriptionObserver((OSSubscriptionStateChanges changes) {
    // Will be called whenever the subscription changes
    // (ie. user gets registered with OneSignal and gets a user ID)
  });
  OneSignal.shared.setEmailSubscriptionObserver((OSEmailSubscriptionStateChanges emailChanges) {
    // Will be called whenever then user's email subscription changes
    // (ie. OneSignal.setEmail(email) is called and the user gets registered
  });

  // check if user is logged in
  AuthProvider authProvider = context.read<AuthProvider>();
  bool isLoggedIn = await authProvider.isLoggedIn();

  if (isLoggedIn) {
    // get user id
    String userId = authProvider.user!.id!;

    // set user id
    OneSignal.shared.setExternalUserId(userId);
    // email subscription
    // OneSignal.shared.setEmail(email: authProvider.user!.email!);
  }
  }
}
