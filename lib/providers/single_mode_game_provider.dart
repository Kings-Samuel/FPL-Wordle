import 'dart:convert';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/consts/appwrite_consts.dart';
import 'package:fplwordle/helpers/utils/init_appwrite.dart';
import 'package:fplwordle/helpers/utils/init_sec_storage.dart';
import 'package:fplwordle/helpers/widgets/snack_bar_helper.dart';
import 'package:fplwordle/models/single_mode_puzzle.dart';
import 'package:fplwordle/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import '../consts/shared_prefs_consts.dart';
import '../models/player.dart';
import '../models/profile.dart';

class SingleModeGameProvider extends ChangeNotifier {
  String _error = '';
  Duration _durationUntilNextGame = Duration.zero;
  SingleModePuzzle? _puzzle;

  Duration get durationUntilNextGame => _durationUntilNextGame;
  SingleModePuzzle? get puzzle => _puzzle;
  String get error => _error;

  SingleModeGameProvider() {
    setDurationUntilNextGame();
  }

  Future<Duration> setDurationUntilNextGame() async {
    // duration until next game at 17:00 UTC
    final DateTime now = DateTime.now().toUtc();
    final DateTime nextGame = DateTime(now.year, now.month, now.day, 17, 0, 0).toUtc();

    if (now.isBefore(nextGame)) {
      _durationUntilNextGame = nextGame.difference(now);
    } else {
      _durationUntilNextGame = nextGame.add(const Duration(days: 1)).difference(now);
    }

    return _durationUntilNextGame;
  }

  Future<bool> isGameInSession(ProfileProvider profileProvider) async {
    // ceheck last game time
    String? lastGameId = await secStorage.read(key: SharedPrefsConsts.lastGameId);

    // if last game time is null, then no game has been played yet
    if (lastGameId == null) {
      return false;
    } else {
      final now = DateTime.now().toUtc();
      DateTime lastGameTimeDate = DateTime.parse(lastGameId);
      final five5PMtoday = DateTime(now.year, now.month, now.day, 17, 0, 0).toUtc();
      String todayDate = now.toString().split(" ")[0];
      String todayDateString = "$todayDate 17:00:00";
      final five5PMyesterday = five5PMtoday.subtract(const Duration(days: 1));

      // checking if the last game id is today at 17:00 UTC
      if (lastGameId == todayDateString) {
        return true;
      }
      // checking if the last game id is yesterday at 17:00 UTC
      else if (lastGameTimeDate.isAtSameMomentAs(five5PMyesterday) ||
          lastGameTimeDate.isAfter(five5PMyesterday) && now.isBefore(five5PMtoday)) {
        return true;
      } else {
        await profileProvider.increaseForfeitCount();
        await secStorage.delete(key: SharedPrefsConsts.lastGameId);
        await secStorage.delete(key: SharedPrefsConsts.gameInSession);
        return false;
      }
    }
  }

  Future<void> loadNewGame(BuildContext context) async {
    try {
      DateTime dateTime = DateTime.now().toUtc();
      DateTime yesterday = dateTime.subtract(const Duration(days: 1));
      DateTime fivePMtoday = DateTime(dateTime.year, dateTime.month, dateTime.day, 17, 0, 0).toUtc();
      String documentId = dateTime.toString().split(" ")[0]; // today date
      String yesterdayDocumentId = yesterday.toString().split(" ")[0]; // yesterday date
      bool canLoadToday = dateTime.isAtSameMomentAs(fivePMtoday) || dateTime.isAfter(fivePMtoday);
      int timesPlayed = 0;

      if (canLoadToday) {
        final res = await database.getDocument(
            databaseId: AppwriteConsts.db, collectionId: AppwriteConsts.dailyPuzzle, documentId: documentId);
        timesPlayed = res.data["timesPlayed"];
        _puzzle = SingleModePuzzle.fromJson(res.data);
      } else {
        final res = await database.getDocument(
            databaseId: AppwriteConsts.db, collectionId: AppwriteConsts.dailyPuzzle, documentId: yesterdayDocumentId);
        timesPlayed = res.data["timesPlayed"];
        _puzzle = SingleModePuzzle.fromJson(res.data);
      }

      // save time of game
      dateTime = DateTime.now().toUtc();
      String id = canLoadToday ? documentId : yesterdayDocumentId;
      final lastGameId = "$id 17:00:00";
      await secStorage.write(key: SharedPrefsConsts.lastGameId, value: lastGameId);

      // check difficulty
      Profile profile = Profile();
      if (context.mounted) profile = context.read<ProfileProvider>().profile!;
      int difficulty = profile.difficulty!;

      //  save game in session
      _puzzle!.lives = difficulty == 1
          ? 20
          : difficulty == 2
              ? 15
              : 10;
      _puzzle!.hints = 3;

      // create playersUnveiled
      Player playerUnveiled = Player(
          firstName: "",
          secondName: "",
          elementType: 0,
          team: 0,
          nowCost: 0,
          totalPoints: 0,
          bonus: 0,
          goalsScored: 0,
          assists: 0,
          cleanSheets: 0,
          goalsConceded: 0,
          ownGoals: 0,
          penaltiesMissed: 0,
          yellowCards: 0,
          redCards: 0,
          starts: 0,
          selectedByPercent: "",
          pointsPerGame: "");
      String playerUnveiledEncoded = jsonEncode(playerUnveiled.toJson());
      puzzle!.player1unveiled = puzzle!.player2unveiled =
          puzzle!.player3unveiled = puzzle!.player4unveiled = puzzle!.player5unveiled = playerUnveiledEncoded;

      await secStorage.write(key: SharedPrefsConsts.gameInSession, value: jsonEncode(_puzzle!.toJson()));

      // increase game count (timesPlayed)
      await database.updateDocument(
          databaseId: AppwriteConsts.db,
          collectionId: AppwriteConsts.dailyPuzzle,
          documentId: canLoadToday ? documentId : yesterdayDocumentId,
          data: {"timesPlayed": timesPlayed + 1});

      notifyListeners();
    } on AppwriteException catch (e) {
      _error = e.message!;
      debugPrint(_error);
      snackBarHelper(context, message: _error, type: AnimatedSnackBarType.error);
    }
  }

  Future<void> loadGameInSession() async {
    String? puzzleEncoded = await secStorage.read(key: SharedPrefsConsts.gameInSession);
    if (puzzleEncoded != null) {
      _puzzle = SingleModePuzzle.fromJson(jsonDecode(puzzleEncoded));
      notifyListeners();
    }
  }
}
