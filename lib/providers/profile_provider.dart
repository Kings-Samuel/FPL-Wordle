import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/consts/appwrite_consts.dart';
import 'package:fplwordle/helpers/utils/init_appwrite.dart';
import 'package:fplwordle/helpers/utils/init_sec_storage.dart';
import 'package:fplwordle/models/profile.dart';
import 'package:fplwordle/models/user.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../consts/shared_prefs_consts.dart';

class ProfileProvider extends ChangeNotifier {
  String _error = '';
  final String _db = AppwriteConsts.db;
  final String _collection = AppwriteConsts.profile;
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
      String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);

      // check if user is null (user is null when user is not logged in)
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
        // _profile!.achievements!.id = user.id;

        // check if doc already exixst.
        final res = await database.getDocument(databaseId: _db, collectionId: _collection, documentId: user.id!);

        _profile = Profile.fromJson(res.data);
        // if not exists, create new profile document (handled by catch block)/

        // clear local storage
        await secStorage.delete(key: SharedPrefsConsts.profile);
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
        String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);

        if (profile_ == null) {
          _profile = Profile(
            id: user!.id,
            coins: 0,
            gamesPlayed: 0,
            gamesWon: 0,
            gamesLost: 0,
            gamesAbandoned: 0,
            longestWinStreak: 0,
            difficulty: 1,
            // level: 1,
            xp: 0,
            highScore: 0,
            // playedToday: 0,
            playersFound: 0,
            correctFirstGuess: 0,
            noHintsUsed: 0,
            scoresShared: 0,
            // multiplayerModePlayed: 0,
            // winsInMultiplayerMode: 0,
            // achievements: Achievements(
            //     id: user.id,
            //     gamesPlayedX5: false,
            //     gamesPlayedX10: false,
            //     gamesPlayedX20: false,
            //     gamesInOneDayX3: false,
            //     winningStreakX5: false,
            //     playersFoundX25: false,
            //     playersFoundX50: false,
            //     correctFirstGuessX10: false,
            //     playAgameInMultiPlayerMode: false,
            //     winsInMultiplayerModeX5: false,
            //     noHintsUsedX5: false,
            //     scoresSharedX3: false,
            //     scoresSharedX10: false)
          );
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
          // _profile!.achievements!.id = user.id;

          final res = database.createDocument(
              databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: _profile!.toJson());

          res.then((value) async {
            notifyListeners();
            // debugPrint(value.toMap().toString());
            // clear local storage
            await secStorage.delete(key: SharedPrefsConsts.profile);
          }).catchError((e) {
            debugPrint(e.toString());
          });
        }
      }
    }
  }

  // create profile locally
  Future<void> createLocalProfile() async {
    // check if there is a profile document for this user on local storage
    String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);

    if (profile_ == null) {
      _profile = Profile(
        gamesPlayed: 0,
        gamesWon: 0,
        gamesLost: 0,
        gamesAbandoned: 0,
        longestWinStreak: 0,
        // playedToday: 0,
        playersFound: 0,
        correctFirstGuess: 0,
        noHintsUsed: 0,
        scoresShared: 0,
        // multiplayerModePlayed: 0,
        // winsInMultiplayerMode: 0,
        // level: 1,
        xp: 0,
        highScore: 0,
        difficulty: 1,
        // achievements: Achievements(
        //   gamesPlayedX5: false,
        //   gamesPlayedX10: false,
        //   gamesPlayedX20: false,
        //   gamesInOneDayX3: false,
        //   winningStreakX5: false,
        //   playersFoundX25: false,
        //   playersFoundX50: false,
        //   correctFirstGuessX10: false,
        //   playAgameInMultiPlayerMode: false,
        //   scoresSharedX3: false,
        //   scoresSharedX10: false,
        //   noHintsUsedX5: false,
        //   winsInMultiplayerModeX5: false,
        // ),
      );
      String profileString = jsonEncode(_profile!.toJson());
      await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);

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
    String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);

    if (profile_ != null) {
      _profile!.difficulty = level;
      String profileString = jsonEncode(_profile!.toJson());

      await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);

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
    String? notifStatus = await secStorage.read(key: SharedPrefsConsts.notifStatus);

    if (notifStatus == null || notifStatus == "true") {
      _isNotificationEnabled = true;
    } else {
      _isNotificationEnabled = false;
    }
  }

  // toggle notifications
  Future<void> toggleNotifications() async {
    if (_isNotificationEnabled) {
      _isNotificationEnabled = false;
      await secStorage.write(key: SharedPrefsConsts.notifStatus, value: "false");
      await OneSignal.shared.disablePush(true);
      notifyListeners();
    } else {
      _isNotificationEnabled = true;
      await secStorage.write(key: SharedPrefsConsts.notifStatus, value: "true");
      await OneSignal.shared.disablePush(false);
      notifyListeners();
    }
  }

  // ! PROFILE AND ACHIEVEMENTS UPDATE METHODS

  Future<void> increaseGamesPlayedCount() async {
    // check if there is a profile document for this user on local storage
    String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);

    if (profile_ != null) {
      _profile!.gamesPlayed! + 1;
      String profileString = jsonEncode(_profile!.toJson());

      await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);

      notifyListeners();
    } else {
      _profile!.gamesPlayed! + 1;
      await database.updateDocument(
          databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: _profile!.toJson());
      notifyListeners();
    }
  }

  Future<void> increaseGamesWonCount() async {
    // check if there is a profile document for this user on local storage
    String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);

    if (profile_ != null) {
      _profile!.gamesWon! + 1;
      String profileString = jsonEncode(_profile!.toJson());

      await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);

      notifyListeners();
    } else {
      _profile!.gamesWon! + 1;
      await database.updateDocument(
          databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: _profile!.toJson());
      notifyListeners();
    }
  }

  Future<void> increaseGamesLostCount() async {
    // check if there is a profile document for this user on local storage
    String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);

    if (profile_ != null) {
      _profile!.gamesLost! + 1;
      String profileString = jsonEncode(_profile!.toJson());

      await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);

      notifyListeners();
    } else {
      _profile!.gamesLost! + 1;
      await database.updateDocument(
          databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: _profile!.toJson());

      notifyListeners();
    }
  }

  Future<void> increaseGamesAbandonedCount() async {
    // check if there is a profile document for this user on local storage
    String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);

    if (profile_ != null) {
      _profile!.gamesAbandoned! + 1;
      String profileString = jsonEncode(_profile!.toJson());

      await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);

      notifyListeners();
    } else {
      _profile!.gamesAbandoned! + 1;
      await database.updateDocument(
          databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: _profile!.toJson());

      notifyListeners();
    }
  }

  // Future<void> increaseWinStreakCount() async {
  //   // check if there is a profile document for this user on local storage
  //   String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);
  //   if (profile_ != null) {
  //     _profile!.winStreak! + 1;
  //     String profileString = jsonEncode(_profile!.toJson());
  //     await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);
  //     notifyListeners();
  //   } else {
  //     _profile!.winStreak! + 1;
  //     await database.updateDocument(
  //         databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: {"winStreak": _profile!.winStreak});
  //     notifyListeners();
  //   }
  // }

  Future<void> increaseLongestWinStreakCount(int winStreak) async {
    // check if there is a profile document for this user on local storage
    String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);
    int longestWinStreak = _profile!.longestWinStreak!;

    if (profile_ != null) {
      if (winStreak > longestWinStreak) {
        _profile!.longestWinStreak = winStreak;
        String profileString = jsonEncode(_profile!.toJson());

        await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);

        notifyListeners();
      }
    } else {
      if (winStreak > longestWinStreak) {
        _profile!.longestWinStreak = winStreak;
        await database.updateDocument(
            databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: _profile!.toJson());
        notifyListeners();
      }
    }
  }

  // Future<void> increasePlayedTodayCount(int playedToday) async {
  //   // check if there is a profile document for this user on local storage
  //   String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);
  //   int playedToday_ = _profile!.playedToday!;
  //   if (profile_ != null) {
  //     if (playedToday > playedToday_) {
  //       _profile!.playedToday = playedToday;
  //       String profileString = jsonEncode(_profile!.toJson());
  //       await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);
  //       notifyListeners();
  //     }
  //   } else {
  //     if (playedToday > playedToday_) {
  //       _profile!.playedToday = playedToday;
  //       await database.updateDocument(
  //           databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: _profile!.toJson());
  //       notifyListeners();
  //     }
  //   }
  // }

  Future<void> increasePlayersFoundCount() async {
    // check if there is a profile document for this user on local storage
    String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);

    if (profile_ != null) {
      _profile!.playersFound! + 1;
      String profileString = jsonEncode(_profile!.toJson());

      await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);

      notifyListeners();
    } else {
      _profile!.playersFound! + 1;
      await database.updateDocument(
          databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: _profile!.toJson());
      notifyListeners();
    }
  }

  Future<void> increaseCorrectFirstGuessCount() async {
    // check if there is a profile document for this user on local storage
    String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);

    if (profile_ != null) {
      _profile!.correctFirstGuess! + 1;
      String profileString = jsonEncode(_profile!.toJson());

      await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);

      notifyListeners();
    } else {
      _profile!.correctFirstGuess! + 1;
      await database.updateDocument(
          databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: _profile!.toJson());
      notifyListeners();
    }
  }

  Future<void> increaseNoHintsUsedCount() async {
    // check if there is a profile document for this user on local storage
    String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);

    if (profile_ != null) {
      _profile!.noHintsUsed! + 1;
      String profileString = jsonEncode(_profile!.toJson());

      await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);

      notifyListeners();
    } else {
      _profile!.noHintsUsed! + 1;
      await database.updateDocument(
          databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: _profile!.toJson());
      notifyListeners();
    }
  }

  Future<void> increaseScoresSharedCount() async {
    // check if there is a profile document for this user on local storage
    String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);

    if (profile_ != null) {
      _profile!.scoresShared! + 1;
      String profileString = jsonEncode(_profile!.toJson());

      await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);

      notifyListeners();
    } else {
      _profile!.scoresShared! + 1;
      await database.updateDocument(
          databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: _profile!.toJson());
      notifyListeners();
    }
  }

  // Future<void> increaseMultiplayerModePlayedCount(int multiplayerModePlayed) async {
  //   // check if there is a profile document for this user on local storage
  //   String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);
  //   int multiplayerModePlayed_ = _profile!.multiplayerModePlayed!;
  //   if (profile_ != null) {
  //     if (multiplayerModePlayed > multiplayerModePlayed_) {
  //       _profile!.multiplayerModePlayed = multiplayerModePlayed;
  //       String profileString = jsonEncode(_profile!.toJson());
  //       await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);
  //       notifyListeners();
  //     }
  //   } else {
  //     if (multiplayerModePlayed > multiplayerModePlayed_) {
  //       _profile!.multiplayerModePlayed = multiplayerModePlayed;
  //       await database.updateDocument(
  //           databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: _profile!.toJson());
  //       notifyListeners();
  //     }
  //   }
  // }

  Future<void> increaseXP(int newXP) async {
    // check if there is a profile document for this user on local storage
    String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);

    if (profile_ != null) {
      _profile!.xp! + newXP;
      String profileString = jsonEncode(_profile!.toJson());

      await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);

      notifyListeners();
    } else {
      _profile!.xp! + newXP;
      await database.updateDocument(
          databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: _profile!.toJson());
      notifyListeners();
    }
  }

  Future<void> setHighScore(int highScore) async {
    // check if there is a profile document for this user on local storage
    String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);

    if (profile_ != null) {
      _profile!.highScore = highScore;
      String profileString = jsonEncode(_profile!.toJson());

      await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);

      notifyListeners();
    } else {
      _profile!.highScore = highScore;
      await database.updateDocument(
          databaseId: _db, collectionId: _collection, documentId: _profile!.id!, data: _profile!.toJson());
      notifyListeners();
    }
  }

  // Future<void> increaseWinsInMultiplayerModeCount(int winsInMultiplayerMode) async {
  //   // check if there is a profile document for this user on local storage
  //   String? profile_ = await secStorage.read(key: SharedPrefsConsts.profile);
  //   int winsInMultiplayerMode_ = _profile!.winsInMultiplayerMode!;
  //   if (profile_ != null) {
  //     if (winsInMultiplayerMode > winsInMultiplayerMode_) {
  //       _profile!.winsInMultiplayerMode = winsInMultiplayerMode;
  //       String profileString = jsonEncode(_profile!.toJson());
  //       await secStorage.write(key: SharedPrefsConsts.profile, value: profileString);
  //       notifyListeners();
  //     }
  //   } else {
  //     if (winsInMultiplayerMode > winsInMultiplayerMode_) {
  //       _profile!.winsInMultiplayerMode = winsInMultiplayerMode;
  //       await database.updateDocument(
  //           databaseId: _db,
  //           collectionId: _collection,
  //           documentId: _profile!.id!,
  //           data: {"winsInMultiplayerMode": _profile!.winsInMultiplayerMode});
  //       notifyListeners();
  //     }
  //   }
  // }
}
