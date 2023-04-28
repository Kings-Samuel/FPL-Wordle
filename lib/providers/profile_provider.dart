import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/consts.dart';
import 'package:fplwordle/helpers/utils/init_appwrite.dart';
import 'package:fplwordle/helpers/utils/sec_storage.dart';
import 'package:fplwordle/models/profile.dart';
import 'package:fplwordle/models/user.dart';

class ProfileProvider extends ChangeNotifier {
  String _error = '';
  final String _db = Consts.db;
  final String _collection = Consts.profile;
  Profile? _profile;
  bool _isNotificationEnabled = true;

  ProfileProvider() {
    checkNotificationStatus();
  }

  String get error => _error;
  Profile? get profile => _profile;
  bool get isNotificationEnabled => _isNotificationEnabled;

  // create user profile document
  Future<void> createOrConfirmProfile({User? user}) async {
    try {
      // check if there is a profile document for this user on local storage
      String? profile_ = await secStorage.read(key: 'profile');

      // check if useris null (user is null when user is not logged in)
      if (user!.id == null && profile_ != null) {
        Map<String, dynamic> profileJson = jsonDecode(profile_);
        _profile = Profile.fromJson(profileJson);
        notifyListeners();
        return;
      }

      // if exists, save to appwrite and clear local storage
      if (profile_ != null && user.id != null) {
        // decode profile string to json
        Map<String, dynamic> profileJson = jsonDecode(profile_);
        _profile = Profile.fromJson(profileJson);
        _profile!.coins = 0;
        _profile!.achievements!.id = user.id;

        // check if doc already exixst.
        final res = await database.getDocument(databaseId: _db, collectionId: _collection, documentId: user.id!);

        _profile = Profile.fromJson(res.data);
        // if not exists, create new profile document (handled by catch block)/

        // clear local storage
        await secStorage.delete(key: 'profile');
      } else {
        // check if doc already exixst.
        final res = await database.getDocument(databaseId: _db, collectionId: _collection, documentId: user.id!);

        _profile = Profile.fromJson(res.data);
        // if not exists, create new profile document (handled by catch block)
      }

      notifyListeners();
    } on AppwriteException catch (e) {
      _error = e.message!;
      debugPrint(_error);

      // if profile document does not exist, create new profile document
      if (_error == "Document with the requested ID could not be found.") {
        // check if local profile exists
        String? profile_ = await secStorage.read(key: 'profile');

        if (profile_ == null) {
          _profile = Profile(
              id: user!.id,
              coins: 0,
              gamesPlayed: 0,
              gamesWon: 0,
              gamesLost: 0,
              gamesAbandoned: 0,
              winStreak: 0,
              longestWinStreak: 0,
              difficulty: 1,
              level: 1,
              xp: 0,
              playedToday: 0,
              playersFound: 0,
              correctFirstGuess: 0,
              noHintsUsed: 0,
              scoresShared: 0,
              multiplayerModePlayed: 0,
              winsInMultiplayerMode: 0,
              achievements: Achievements(
                  id: user.id,
                  gamesPlayedX5: false,
                  gamesPlayedX10: false,
                  gamesPlayedX20: false,
                  gamesInOneDayX3: false,
                  winningStreakX5: false,
                  playersFoundX25: false,
                  playersFoundX50: false,
                  correctFirstGuessX10: false,
                  playAgameInMultiPlayerMode: false,
                  winsInMultiplayerModeX5: false,
                  noHintsUsedX5: false,
                  scoresSharedX3: false,
                  scoresSharedX10: false));
          final res = database.createDocument(
              databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: _profile!.toJson());

          res.then((value) {
            notifyListeners();
            // debugPrint(value.toMap().toString());
          }).catchError((e) {
            debugPrint(e.toString());
          });
        } else {
          Map<String, dynamic> profileJson = jsonDecode(profile_);
          _profile = Profile.fromJson(profileJson);
          _profile!.id = user!.id;
          _profile!.coins = 0;
          _profile!.achievements!.id = user.id;

          final res = database.createDocument(
              databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: _profile!.toJson());

          res.then((value) async {
            notifyListeners();
            // debugPrint(value.toMap().toString());
            // clear local storage
            await secStorage.delete(key: 'profile');
          }).catchError((e) {
            debugPrint(e.toString());
          });
        }
      }
    }
  }

  // create profile locally
  Future<void> creatreLocalProfile() async {
    // check if there is a profile document for this user on local storage
    String? profile_ = await secStorage.read(key: 'profile');

    if (profile_ == null) {
      _profile = Profile(
        gamesPlayed: 0,
        gamesWon: 0,
        gamesLost: 0,
        gamesAbandoned: 0,
        winStreak: 0,
        longestWinStreak: 0,
        playedToday: 0,
        playersFound: 0,
        correctFirstGuess: 0,
        noHintsUsed: 0,
        scoresShared: 0,
        multiplayerModePlayed: 0,
        winsInMultiplayerMode: 0,
        level: 1,
        xp: 0,
        difficulty: 1,
        achievements: Achievements(
          gamesPlayedX5: false,
          gamesPlayedX10: false,
          gamesPlayedX20: false,
          gamesInOneDayX3: false,
          winningStreakX5: false,
          playersFoundX25: false,
          playersFoundX50: false,
          correctFirstGuessX10: false,
          playAgameInMultiPlayerMode: false,
          scoresSharedX3: false,
          scoresSharedX10: false,
          noHintsUsedX5: false,
          winsInMultiplayerModeX5: false,
        ),
      );
      String profileString = jsonEncode(_profile!.toJson());
      await secStorage.write(key: 'profile', value: profileString);

      notifyListeners();
    } else {
      Map<String, dynamic> profileJson = jsonDecode(profile_);
      _profile = Profile.fromJson(profileJson);
      notifyListeners();
    }
  }

  // update difficulty
  Future<void> updateDifficulty(int level) async {
    // check if there is a profile document for this user on local storage
    String? profile_ = await secStorage.read(key: "profile");

    if (profile_ != null) {
      _profile!.difficulty = level;
      String profileString = jsonEncode(_profile!.toJson());

      await secStorage.write(key: "profile", value: profileString);

      notifyListeners();
    } else {
      _profile!.difficulty = level;
      await database.updateDocument(
          databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: {"difficulty": level});
      notifyListeners();
    }
  }

  // check if user has enabled notifications
  Future<void> checkNotificationStatus() async {
    String? notifStatus = await secStorage.read(key: "notifStatus");

    if (notifStatus == null || notifStatus == "true") {
      _isNotificationEnabled = true;
      notifyListeners();
    } else {
      _isNotificationEnabled = false;
      notifyListeners();
    }
    // TODO: check android and iOS notification channels
  }

  // toggle notifications
  Future<void> toggleNotifications() async {
    String? notifStatus = await secStorage.read(key: "notifStatus");

    if (notifStatus == null || notifStatus == "true") {
      _isNotificationEnabled = false;
      await secStorage.write(key: "notifStatus", value: "false");
      notifyListeners();
    } else {
      _isNotificationEnabled = true;
      await secStorage.write(key: "notifStatus", value: "true");
      notifyListeners();
    }
    // TODO: check android and iOS notification channels
  }
}
