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
  bool _scaleAttrCards = false;

  Duration get durationUntilNextGame => _durationUntilNextGame;
  SingleModePuzzle? get puzzle => _puzzle;
  String get error => _error;
  bool get scaleAttrCards => _scaleAttrCards;

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
      _puzzle!.player1unveiled = _puzzle!.player2unveiled =
          _puzzle!.player3unveiled = _puzzle!.player4unveiled = _puzzle!.player5unveiled = playerUnveiledEncoded;

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

  void setScaleAttrIcons(bool value) {
    _scaleAttrCards = value;
    notifyListeners();
  }

  Future<void> setPlayerUnveiled(
      {required Player player, required Player playerUnveiled, required int puzzlePosition}) async {
    playerUnveiled.isUnveiled = true;

    // update player unveiled
    switch (puzzlePosition) {
      case 1:
        _puzzle!.player1unveiled = jsonEncode(playerUnveiled.toJson());
      case 2:
        _puzzle!.player2unveiled = jsonEncode(playerUnveiled.toJson());
      case 3:
        _puzzle!.player3unveiled = jsonEncode(playerUnveiled.toJson());
      case 4:
        _puzzle!.player4unveiled = jsonEncode(playerUnveiled.toJson());
      case 5:
        _puzzle!.player5unveiled = jsonEncode(playerUnveiled.toJson());
        break;
      default:
    }

    // update game in session
    await secStorage.write(key: SharedPrefsConsts.gameInSession, value: jsonEncode(_puzzle!.toJson()));

    notifyListeners();
    // show graphic info to user
  }

  Future<void> setGameComplete() async {
    _puzzle!.isFinished = true;
    await secStorage.write(key: SharedPrefsConsts.gameInSession, value: jsonEncode(_puzzle!.toJson()));
    notifyListeners();
    // show graphic info to user
  }

  Future<void> useHint(
      {required Player player, required Player playerUnveiled, String? attribute, required int puzzlePosition}) async {
    // attribute is null when the user selects team
    if (attribute == null) {
      playerUnveiled.team = player.team;

      // update player unveiled in puzzle
      switch (puzzlePosition) {
        case 1:
          _puzzle!.player1unveiled = jsonEncode(playerUnveiled.toJson());
        case 2:
          _puzzle!.player2unveiled = jsonEncode(playerUnveiled.toJson());
        case 3:
          _puzzle!.player3unveiled = jsonEncode(playerUnveiled.toJson());
        case 4:
          _puzzle!.player4unveiled = jsonEncode(playerUnveiled.toJson());
        case 5:
          _puzzle!.player5unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        default:
      }

      // find other players with same team
      Player player1 = Player.fromJson(jsonDecode(_puzzle!.player1!));
      Player player2 = Player.fromJson(jsonDecode(_puzzle!.player2!));
      Player player3 = Player.fromJson(jsonDecode(_puzzle!.player3!));
      Player player4 = Player.fromJson(jsonDecode(_puzzle!.player4!));
      Player player5 = Player.fromJson(jsonDecode(_puzzle!.player5!));

      Player player1Unveiled = Player.fromJson(jsonDecode(_puzzle!.player1unveiled!));
      Player player2Unveiled = Player.fromJson(jsonDecode(_puzzle!.player2unveiled!));
      Player player3Unveiled = Player.fromJson(jsonDecode(_puzzle!.player3unveiled!));
      Player player4Unveiled = Player.fromJson(jsonDecode(_puzzle!.player4unveiled!));
      Player player5Unveiled = Player.fromJson(jsonDecode(_puzzle!.player5unveiled!));

      if (player1.team == player.team) {
        player1Unveiled.team = player.team;
        _puzzle!.player1unveiled = jsonEncode(player1Unveiled.toJson());
      }

      if (player2.team == player.team) {
        player2Unveiled.team = player.team;
        _puzzle!.player2unveiled = jsonEncode(player2Unveiled.toJson());
      }

      if (player3.team == player.team) {
        player3Unveiled.team = player.team;
        _puzzle!.player3unveiled = jsonEncode(player3Unveiled.toJson());
      }

      if (player4.team == player.team) {
        player4Unveiled.team = player.team;
        _puzzle!.player4unveiled = jsonEncode(player4Unveiled.toJson());
      }

      if (player5.team == player.team) {
        player5Unveiled.team = player.team;
        _puzzle!.player5unveiled = jsonEncode(player5Unveiled.toJson());
      }
    }

    // totalPoints
    if (attribute == "totalPoints") {
      playerUnveiled.totalPoints = player.totalPoints;

      // update player unveiled in puzzle
      switch (puzzlePosition) {
        case 1:
          _puzzle!.player1unveiled = jsonEncode(playerUnveiled.toJson());
        case 2:
          _puzzle!.player2unveiled = jsonEncode(playerUnveiled.toJson());
        case 3:
          _puzzle!.player3unveiled = jsonEncode(playerUnveiled.toJson());
        case 4:
          _puzzle!.player4unveiled = jsonEncode(playerUnveiled.toJson());
        case 5:
          _puzzle!.player5unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        default:
      }

      // find other players with same totalPoints
      Player player1 = Player.fromJson(jsonDecode(_puzzle!.player1!));
      Player player2 = Player.fromJson(jsonDecode(_puzzle!.player2!));
      Player player3 = Player.fromJson(jsonDecode(_puzzle!.player3!));
      Player player4 = Player.fromJson(jsonDecode(_puzzle!.player4!));
      Player player5 = Player.fromJson(jsonDecode(_puzzle!.player5!));

      if (player1.totalPoints == player.totalPoints) {
        _puzzle!.player1unveiled = jsonEncode(player1.toJson());
      }

      if (player2.totalPoints == player.totalPoints) {
        _puzzle!.player2unveiled = jsonEncode(player2.toJson());
      }

      if (player3.totalPoints == player.totalPoints) {
        _puzzle!.player3unveiled = jsonEncode(player3.toJson());
      }

      if (player4.totalPoints == player.totalPoints) {
        _puzzle!.player4unveiled = jsonEncode(player4.toJson());
      }

      if (player5.totalPoints == player.totalPoints) {
        _puzzle!.player5unveiled = jsonEncode(player5.toJson());
      }
    }

    // bonus
    if (attribute == "bonus") {
      playerUnveiled.bonus = player.bonus;

      // update player unveiled in puzzle
      switch (puzzlePosition) {
        case 1:
          _puzzle!.player1unveiled = jsonEncode(playerUnveiled.toJson());
        case 2:
          _puzzle!.player2unveiled = jsonEncode(playerUnveiled.toJson());
        case 3:
          _puzzle!.player3unveiled = jsonEncode(playerUnveiled.toJson());
        case 4:
          _puzzle!.player4unveiled = jsonEncode(playerUnveiled.toJson());
        case 5:
          _puzzle!.player5unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        default:
      }

      // find other players with same bonus
      Player player1 = Player.fromJson(jsonDecode(_puzzle!.player1!));
      Player player2 = Player.fromJson(jsonDecode(_puzzle!.player2!));
      Player player3 = Player.fromJson(jsonDecode(_puzzle!.player3!));
      Player player4 = Player.fromJson(jsonDecode(_puzzle!.player4!));
      Player player5 = Player.fromJson(jsonDecode(_puzzle!.player5!));

      Player player1Unveiled = Player.fromJson(jsonDecode(_puzzle!.player1unveiled!));
      Player player2Unveiled = Player.fromJson(jsonDecode(_puzzle!.player2unveiled!));
      Player player3Unveiled = Player.fromJson(jsonDecode(_puzzle!.player3unveiled!));
      Player player4Unveiled = Player.fromJson(jsonDecode(_puzzle!.player4unveiled!));
      Player player5Unveiled = Player.fromJson(jsonDecode(_puzzle!.player5unveiled!));

      if (player1.bonus == player.bonus) {
        player1Unveiled.bonus = player.bonus;
        _puzzle!.player1unveiled = jsonEncode(player1Unveiled.toJson());
      }

      if (player2.bonus == player.bonus) {
        player2Unveiled.bonus = player.bonus;
        _puzzle!.player2unveiled = jsonEncode(player2Unveiled.toJson());
      }

      if (player3.bonus == player.bonus) {
        player3Unveiled.bonus = player.bonus;
        _puzzle!.player3unveiled = jsonEncode(player3Unveiled.toJson());
      }

      if (player4.bonus == player.bonus) {
        player4Unveiled.bonus = player.bonus;
        _puzzle!.player4unveiled = jsonEncode(player4Unveiled.toJson());
      }

      if (player5.bonus == player.bonus) {
        player5Unveiled.bonus = player.bonus;
        _puzzle!.player5unveiled = jsonEncode(player5Unveiled.toJson());
      }
    }

    // goalsScored
    if (attribute == "goalsScored") {
      playerUnveiled.goalsScored = player.goalsScored;

      // update player unveiled in puzzle
      switch (puzzlePosition) {
        case 1:
          _puzzle!.player1unveiled = jsonEncode(playerUnveiled.toJson());
        case 2:
          _puzzle!.player2unveiled = jsonEncode(playerUnveiled.toJson());
        case 3:
          _puzzle!.player3unveiled = jsonEncode(playerUnveiled.toJson());
        case 4:
          _puzzle!.player4unveiled = jsonEncode(playerUnveiled.toJson());
        case 5:
          _puzzle!.player5unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        default:
      }

      // find other players with same goalsScored
      Player player1 = Player.fromJson(jsonDecode(_puzzle!.player1!));
      Player player2 = Player.fromJson(jsonDecode(_puzzle!.player2!));
      Player player3 = Player.fromJson(jsonDecode(_puzzle!.player3!));
      Player player4 = Player.fromJson(jsonDecode(_puzzle!.player4!));
      Player player5 = Player.fromJson(jsonDecode(_puzzle!.player5!));

      Player player1Unveiled = Player.fromJson(jsonDecode(_puzzle!.player1unveiled!));
      Player player2Unveiled = Player.fromJson(jsonDecode(_puzzle!.player2unveiled!));
      Player player3Unveiled = Player.fromJson(jsonDecode(_puzzle!.player3unveiled!));
      Player player4Unveiled = Player.fromJson(jsonDecode(_puzzle!.player4unveiled!));
      Player player5Unveiled = Player.fromJson(jsonDecode(_puzzle!.player5unveiled!));

      if (player1.goalsScored == player.goalsScored) {
        player1Unveiled.goalsScored = player.goalsScored;
        _puzzle!.player1unveiled = jsonEncode(player1Unveiled.toJson());
      }

      if (player2.goalsScored == player.goalsScored) {
        player2Unveiled.goalsScored = player.goalsScored;
        _puzzle!.player2unveiled = jsonEncode(player2Unveiled.toJson());
      }

      if (player3.goalsScored == player.goalsScored) {
        player3Unveiled.goalsScored = player.goalsScored;
        _puzzle!.player3unveiled = jsonEncode(player3Unveiled.toJson());
      }

      if (player4.goalsScored == player.goalsScored) {
        player4Unveiled.goalsScored = player.goalsScored;
        _puzzle!.player4unveiled = jsonEncode(player4Unveiled.toJson());
      }

      if (player5.goalsScored == player.goalsScored) {
        player5Unveiled.goalsScored = player.goalsScored;
        _puzzle!.player5unveiled = jsonEncode(player5Unveiled.toJson());
      }
    }

    // assists
    if (attribute == "assists") {
      playerUnveiled.assists = player.assists;

      // update player unveiled in puzzle
      switch (puzzlePosition) {
        case 1:
          _puzzle!.player1unveiled = jsonEncode(playerUnveiled.toJson());
        case 2:
          _puzzle!.player2unveiled = jsonEncode(playerUnveiled.toJson());
        case 3:
          _puzzle!.player3unveiled = jsonEncode(playerUnveiled.toJson());
        case 4:
          _puzzle!.player4unveiled = jsonEncode(playerUnveiled.toJson());
        case 5:
          _puzzle!.player5unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        default:
      }

      // find other players with same assists
      Player player1 = Player.fromJson(jsonDecode(_puzzle!.player1!));
      Player player2 = Player.fromJson(jsonDecode(_puzzle!.player2!));
      Player player3 = Player.fromJson(jsonDecode(_puzzle!.player3!));
      Player player4 = Player.fromJson(jsonDecode(_puzzle!.player4!));
      Player player5 = Player.fromJson(jsonDecode(_puzzle!.player5!));

      Player player1Unveiled = Player.fromJson(jsonDecode(_puzzle!.player1unveiled!));
      Player player2Unveiled = Player.fromJson(jsonDecode(_puzzle!.player2unveiled!));
      Player player3Unveiled = Player.fromJson(jsonDecode(_puzzle!.player3unveiled!));
      Player player4Unveiled = Player.fromJson(jsonDecode(_puzzle!.player4unveiled!));
      Player player5Unveiled = Player.fromJson(jsonDecode(_puzzle!.player5unveiled!));

      if (player1.assists == player.assists) {
        player1Unveiled.assists = player.assists;
        _puzzle!.player1unveiled = jsonEncode(player1Unveiled.toJson());
      }

      if (player2.assists == player.assists) {
        player2Unveiled.assists = player.assists;
        _puzzle!.player2unveiled = jsonEncode(player2Unveiled.toJson());
      }

      if (player3.assists == player.assists) {
        player3Unveiled.assists = player.assists;
        _puzzle!.player3unveiled = jsonEncode(player3Unveiled.toJson());
      }

      if (player4.assists == player.assists) {
        player4Unveiled.assists = player.assists;
        _puzzle!.player4unveiled = jsonEncode(player4Unveiled.toJson());
      }

      if (player5.assists == player.assists) {
        player5Unveiled.assists = player.assists;
        _puzzle!.player5unveiled = jsonEncode(player5Unveiled.toJson());
      }
    }

    // cleanSheets
    if (attribute == "cleanSheets") {
      playerUnveiled.cleanSheets = player.cleanSheets;

      // update player unveiled in puzzle
      switch (puzzlePosition) {
        case 1:
          _puzzle!.player1unveiled = jsonEncode(playerUnveiled.toJson());
        case 2:
          _puzzle!.player2unveiled = jsonEncode(playerUnveiled.toJson());
        case 3:
          _puzzle!.player3unveiled = jsonEncode(playerUnveiled.toJson());
        case 4:
          _puzzle!.player4unveiled = jsonEncode(playerUnveiled.toJson());
        case 5:
          _puzzle!.player5unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        default:
      }

      // find other players with same cleanSheets
      Player player1 = Player.fromJson(jsonDecode(_puzzle!.player1!));
      Player player2 = Player.fromJson(jsonDecode(_puzzle!.player2!));
      Player player3 = Player.fromJson(jsonDecode(_puzzle!.player3!));
      Player player4 = Player.fromJson(jsonDecode(_puzzle!.player4!));
      Player player5 = Player.fromJson(jsonDecode(_puzzle!.player5!));

      Player player1Unveiled = Player.fromJson(jsonDecode(_puzzle!.player1unveiled!));
      Player player2Unveiled = Player.fromJson(jsonDecode(_puzzle!.player2unveiled!));
      Player player3Unveiled = Player.fromJson(jsonDecode(_puzzle!.player3unveiled!));
      Player player4Unveiled = Player.fromJson(jsonDecode(_puzzle!.player4unveiled!));
      Player player5Unveiled = Player.fromJson(jsonDecode(_puzzle!.player5unveiled!));

      if (player1.cleanSheets == player.cleanSheets) {
        player1Unveiled.cleanSheets = player.cleanSheets;
        _puzzle!.player1unveiled = jsonEncode(player1Unveiled.toJson());
      }

      if (player2.cleanSheets == player.cleanSheets) {
        player2Unveiled.cleanSheets = player.cleanSheets;
        _puzzle!.player2unveiled = jsonEncode(player2Unveiled.toJson());
      }

      if (player3.cleanSheets == player.cleanSheets) {
        player3Unveiled.cleanSheets = player.cleanSheets;
        _puzzle!.player3unveiled = jsonEncode(player3Unveiled.toJson());
      }

      if (player4.cleanSheets == player.cleanSheets) {
        player4Unveiled.cleanSheets = player.cleanSheets;
        _puzzle!.player4unveiled = jsonEncode(player4Unveiled.toJson());
      }

      if (player5.cleanSheets == player.cleanSheets) {
        player5Unveiled.cleanSheets = player.cleanSheets;
        _puzzle!.player5unveiled = jsonEncode(player5Unveiled.toJson());
      }
    }

    // goalsConceded
    if (attribute == "goalsConceded") {
      playerUnveiled.goalsConceded = player.goalsConceded;

      // update player unveiled in puzzle
      switch (puzzlePosition) {
        case 1:
          _puzzle!.player1unveiled = jsonEncode(playerUnveiled.toJson());
        case 2:
          _puzzle!.player2unveiled = jsonEncode(playerUnveiled.toJson());
        case 3:
          _puzzle!.player3unveiled = jsonEncode(playerUnveiled.toJson());
        case 4:
          _puzzle!.player4unveiled = jsonEncode(playerUnveiled.toJson());
        case 5:
          _puzzle!.player5unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        default:
      }

      // find other players with same goalsConceded
      Player player1 = Player.fromJson(jsonDecode(_puzzle!.player1!));
      Player player2 = Player.fromJson(jsonDecode(_puzzle!.player2!));
      Player player3 = Player.fromJson(jsonDecode(_puzzle!.player3!));
      Player player4 = Player.fromJson(jsonDecode(_puzzle!.player4!));
      Player player5 = Player.fromJson(jsonDecode(_puzzle!.player5!));

      Player player1Unveiled = Player.fromJson(jsonDecode(_puzzle!.player1unveiled!));
      Player player2Unveiled = Player.fromJson(jsonDecode(_puzzle!.player2unveiled!));
      Player player3Unveiled = Player.fromJson(jsonDecode(_puzzle!.player3unveiled!));
      Player player4Unveiled = Player.fromJson(jsonDecode(_puzzle!.player4unveiled!));
      Player player5Unveiled = Player.fromJson(jsonDecode(_puzzle!.player5unveiled!));

      if (player1.goalsConceded == player.goalsConceded) {
        player1Unveiled.goalsConceded = player.goalsConceded;
        _puzzle!.player1unveiled = jsonEncode(player1Unveiled.toJson());
      }

      if (player2.goalsConceded == player.goalsConceded) {
        player2Unveiled.goalsConceded = player.goalsConceded;
        _puzzle!.player2unveiled = jsonEncode(player2Unveiled.toJson());
      }

      if (player3.goalsConceded == player.goalsConceded) {
        player3Unveiled.goalsConceded = player.goalsConceded;
        _puzzle!.player3unveiled = jsonEncode(player3Unveiled.toJson());
      }

      if (player4.goalsConceded == player.goalsConceded) {
        player4Unveiled.goalsConceded = player.goalsConceded;
        _puzzle!.player4unveiled = jsonEncode(player4Unveiled.toJson());
      }

      if (player5.goalsConceded == player.goalsConceded) {
        player5Unveiled.goalsConceded = player.goalsConceded;
        _puzzle!.player5unveiled = jsonEncode(player5Unveiled.toJson());
      }
    }

    // ownGoals
    if (attribute == "ownGoals") {
      playerUnveiled.ownGoals = player.ownGoals;

      // update player unveiled in puzzle
      switch (puzzlePosition) {
        case 1:
          _puzzle!.player1unveiled = jsonEncode(playerUnveiled.toJson());
        case 2:
          _puzzle!.player2unveiled = jsonEncode(playerUnveiled.toJson());
        case 3:
          _puzzle!.player3unveiled = jsonEncode(playerUnveiled.toJson());
        case 4:
          _puzzle!.player4unveiled = jsonEncode(playerUnveiled.toJson());
        case 5:
          _puzzle!.player5unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        default:
      }

      // find other players with same ownGoals
      Player player1 = Player.fromJson(jsonDecode(_puzzle!.player1!));
      Player player2 = Player.fromJson(jsonDecode(_puzzle!.player2!));
      Player player3 = Player.fromJson(jsonDecode(_puzzle!.player3!));
      Player player4 = Player.fromJson(jsonDecode(_puzzle!.player4!));
      Player player5 = Player.fromJson(jsonDecode(_puzzle!.player5!));

      Player player1Unveiled = Player.fromJson(jsonDecode(_puzzle!.player1unveiled!));
      Player player2Unveiled = Player.fromJson(jsonDecode(_puzzle!.player2unveiled!));
      Player player3Unveiled = Player.fromJson(jsonDecode(_puzzle!.player3unveiled!));
      Player player4Unveiled = Player.fromJson(jsonDecode(_puzzle!.player4unveiled!));
      Player player5Unveiled = Player.fromJson(jsonDecode(_puzzle!.player5unveiled!));

      if (player1.ownGoals == player.ownGoals) {
        player1Unveiled.ownGoals = player.ownGoals;
        _puzzle!.player1unveiled = jsonEncode(player1Unveiled.toJson());
      }

      if (player2.ownGoals == player.ownGoals) {
        player2Unveiled.ownGoals = player.ownGoals;
        _puzzle!.player2unveiled = jsonEncode(player2Unveiled.toJson());
      }

      if (player3.ownGoals == player.ownGoals) {
        player3Unveiled.ownGoals = player.ownGoals;
        _puzzle!.player3unveiled = jsonEncode(player3Unveiled.toJson());
      }

      if (player4.ownGoals == player.ownGoals) {
        player4Unveiled.ownGoals = player.ownGoals;
        _puzzle!.player4unveiled = jsonEncode(player4Unveiled.toJson());
      }

      if (player5.ownGoals == player.ownGoals) {
        player5Unveiled.ownGoals = player.ownGoals;
        _puzzle!.player5unveiled = jsonEncode(player5Unveiled.toJson());
      }
    }

    // penaltiesMissed
    if (attribute == "penaltiesMissed") {
      playerUnveiled.penaltiesMissed = player.penaltiesMissed;

      // update player unveiled in puzzle
      switch (puzzlePosition) {
        case 1:
          _puzzle!.player1unveiled = jsonEncode(playerUnveiled.toJson());
        case 2:
          _puzzle!.player2unveiled = jsonEncode(playerUnveiled.toJson());
        case 3:
          _puzzle!.player3unveiled = jsonEncode(playerUnveiled.toJson());
        case 4:
          _puzzle!.player4unveiled = jsonEncode(playerUnveiled.toJson());
        case 5:
          _puzzle!.player5unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        default:
      }

      // find other players with penaltiesMissed
      Player player1 = Player.fromJson(jsonDecode(_puzzle!.player1!));
      Player player2 = Player.fromJson(jsonDecode(_puzzle!.player2!));
      Player player3 = Player.fromJson(jsonDecode(_puzzle!.player3!));
      Player player4 = Player.fromJson(jsonDecode(_puzzle!.player4!));
      Player player5 = Player.fromJson(jsonDecode(_puzzle!.player5!));

      Player player1Unveiled = Player.fromJson(jsonDecode(_puzzle!.player1unveiled!));
      Player player2Unveiled = Player.fromJson(jsonDecode(_puzzle!.player2unveiled!));
      Player player3Unveiled = Player.fromJson(jsonDecode(_puzzle!.player3unveiled!));
      Player player4Unveiled = Player.fromJson(jsonDecode(_puzzle!.player4unveiled!));
      Player player5Unveiled = Player.fromJson(jsonDecode(_puzzle!.player5unveiled!));

      if (player1.penaltiesMissed == player.penaltiesMissed) {
        player1Unveiled.penaltiesMissed = player.penaltiesMissed;
        _puzzle!.player1unveiled = jsonEncode(player1Unveiled.toJson());
      }

      if (player2.penaltiesMissed == player.penaltiesMissed) {
        player2Unveiled.penaltiesMissed = player.penaltiesMissed;
        _puzzle!.player2unveiled = jsonEncode(player2Unveiled.toJson());
      }

      if (player3.penaltiesMissed == player.penaltiesMissed) {
        player3Unveiled.penaltiesMissed = player.penaltiesMissed;
        _puzzle!.player3unveiled = jsonEncode(player3Unveiled.toJson());
      }

      if (player4.penaltiesMissed == player.penaltiesMissed) {
        player4Unveiled.penaltiesMissed = player.penaltiesMissed;
        _puzzle!.player4unveiled = jsonEncode(player4Unveiled.toJson());
      }

      if (player5.penaltiesMissed == player.penaltiesMissed) {
        player5Unveiled.penaltiesMissed = player.penaltiesMissed;
        _puzzle!.player5unveiled = jsonEncode(player5Unveiled.toJson());
      }
    }

    // yellowCards
    if (attribute == "yellowCards") {
      playerUnveiled.yellowCards = player.yellowCards;

      // update player unveiled in puzzle
      switch (puzzlePosition) {
        case 1:
          _puzzle!.player1unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        case 2:
          _puzzle!.player2unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        case 3:
          _puzzle!.player3unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        case 4:
          _puzzle!.player4unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        case 5:
          _puzzle!.player5unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        default:
      }

      // find other players with yellowCards
      Player player1 = Player.fromJson(jsonDecode(_puzzle!.player1!));
      Player player2 = Player.fromJson(jsonDecode(_puzzle!.player2!));
      Player player3 = Player.fromJson(jsonDecode(_puzzle!.player3!));
      Player player4 = Player.fromJson(jsonDecode(_puzzle!.player4!));
      Player player5 = Player.fromJson(jsonDecode(_puzzle!.player5!));

      Player player1Unveiled = Player.fromJson(jsonDecode(_puzzle!.player1unveiled!));
      Player player2Unveiled = Player.fromJson(jsonDecode(_puzzle!.player2unveiled!));
      Player player3Unveiled = Player.fromJson(jsonDecode(_puzzle!.player3unveiled!));
      Player player4Unveiled = Player.fromJson(jsonDecode(_puzzle!.player4unveiled!));
      Player player5Unveiled = Player.fromJson(jsonDecode(_puzzle!.player5unveiled!));

      if (player1.yellowCards == player.yellowCards) {
        player1Unveiled.yellowCards = player.yellowCards;
        _puzzle!.player1unveiled = jsonEncode(player1Unveiled.toJson());
      }

      if (player2.yellowCards == player.yellowCards) {
        player2Unveiled.yellowCards = player.yellowCards;
        _puzzle!.player2unveiled = jsonEncode(player2Unveiled.toJson());
      }

      if (player3.yellowCards == player.yellowCards) {
        player3Unveiled.yellowCards = player.yellowCards;
        _puzzle!.player3unveiled = jsonEncode(player3Unveiled.toJson());
      }

      if (player4.yellowCards == player.yellowCards) {
        player4Unveiled.yellowCards = player.yellowCards;
        _puzzle!.player4unveiled = jsonEncode(player4Unveiled.toJson());
      }

      if (player5.yellowCards == player.yellowCards) {
        player5Unveiled.yellowCards = player.yellowCards;
        _puzzle!.player5unveiled = jsonEncode(player5Unveiled.toJson());
      }
    }

    // redCards
    if (attribute == "redCards") {
      playerUnveiled.redCards = player.redCards;

      // update player unveiled in puzzle
      switch (puzzlePosition) {
        case 1:
          _puzzle!.player1unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        case 2:
          _puzzle!.player2unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        case 3:
          _puzzle!.player3unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        case 4:
          _puzzle!.player4unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        case 5:
          _puzzle!.player5unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        default:
      }

      // find other players with redCards
      Player player1 = Player.fromJson(jsonDecode(_puzzle!.player1!));
      Player player2 = Player.fromJson(jsonDecode(_puzzle!.player2!));
      Player player3 = Player.fromJson(jsonDecode(_puzzle!.player3!));
      Player player4 = Player.fromJson(jsonDecode(_puzzle!.player4!));
      Player player5 = Player.fromJson(jsonDecode(_puzzle!.player5!));

      Player player1Unveiled = Player.fromJson(jsonDecode(_puzzle!.player1unveiled!));
      Player player2Unveiled = Player.fromJson(jsonDecode(_puzzle!.player2unveiled!));
      Player player3Unveiled = Player.fromJson(jsonDecode(_puzzle!.player3unveiled!));
      Player player4Unveiled = Player.fromJson(jsonDecode(_puzzle!.player4unveiled!));
      Player player5Unveiled = Player.fromJson(jsonDecode(_puzzle!.player5unveiled!));

      if (player1.redCards == player.redCards) {
        player1Unveiled.redCards = player.redCards;
        _puzzle!.player1unveiled = jsonEncode(player1Unveiled.toJson());
      }

      if (player2.redCards == player.redCards) {
        player2Unveiled.redCards = player.redCards;
        _puzzle!.player2unveiled = jsonEncode(player2Unveiled.toJson());
      }

      if (player3.redCards == player.redCards) {
        player3Unveiled.redCards = player.redCards;
        _puzzle!.player3unveiled = jsonEncode(player3Unveiled.toJson());
      }

      if (player4.redCards == player.redCards) {
        player4Unveiled.redCards = player.redCards;
        _puzzle!.player4unveiled = jsonEncode(player4Unveiled.toJson());
      }

      if (player5.redCards == player.redCards) {
        player5Unveiled.redCards = player.redCards;
        _puzzle!.player5unveiled = jsonEncode(player5Unveiled.toJson());
      }
    }

    // starts
    if (attribute == "starts") {
      playerUnveiled.starts = player.starts;

      // update player unveiled in puzzle
      switch (puzzlePosition) {
        case 1:
          _puzzle!.player1unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        case 2:
          _puzzle!.player2unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        case 3:
          _puzzle!.player3unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        case 4:
          _puzzle!.player4unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        case 5:
          _puzzle!.player5unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        default:
      }

      // find other players with starts
      Player player1 = Player.fromJson(jsonDecode(_puzzle!.player1!));
      Player player2 = Player.fromJson(jsonDecode(_puzzle!.player2!));
      Player player3 = Player.fromJson(jsonDecode(_puzzle!.player3!));
      Player player4 = Player.fromJson(jsonDecode(_puzzle!.player4!));
      Player player5 = Player.fromJson(jsonDecode(_puzzle!.player5!));

      Player player1Unveiled = Player.fromJson(jsonDecode(_puzzle!.player1unveiled!));
      Player player2Unveiled = Player.fromJson(jsonDecode(_puzzle!.player2unveiled!));
      Player player3Unveiled = Player.fromJson(jsonDecode(_puzzle!.player3unveiled!));
      Player player4Unveiled = Player.fromJson(jsonDecode(_puzzle!.player4unveiled!));
      Player player5Unveiled = Player.fromJson(jsonDecode(_puzzle!.player5unveiled!));

      if (player1.starts == player.starts) {
        player1Unveiled.starts = player.starts;
        _puzzle!.player1unveiled = jsonEncode(player1Unveiled.toJson());
      }

      if (player2.starts == player.starts) {
        player2Unveiled.starts = player.starts;
        _puzzle!.player2unveiled = jsonEncode(player2Unveiled.toJson());
      }

      if (player3.starts == player.starts) {
        player3Unveiled.starts = player.starts;
        _puzzle!.player3unveiled = jsonEncode(player3Unveiled.toJson());
      }

      if (player4.starts == player.starts) {
        player4Unveiled.starts = player.starts;
        _puzzle!.player4unveiled = jsonEncode(player4Unveiled.toJson());
      }

      if (player5.starts == player.starts) {
        player5Unveiled.starts = player.starts;
        _puzzle!.player5unveiled = jsonEncode(player5Unveiled.toJson());
      }
    }

    // pointsPerGame
    if (attribute == "pointsPerGame") {
      playerUnveiled.pointsPerGame = player.pointsPerGame;

      // update player unveiled in puzzle
      switch (puzzlePosition) {
        case 1:
          _puzzle!.player1unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        case 2:
          _puzzle!.player2unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        case 3:
          _puzzle!.player3unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        case 4:
          _puzzle!.player4unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        case 5:
          _puzzle!.player5unveiled = jsonEncode(playerUnveiled.toJson());
          break;
        default:
      }

      // find other players with pointsPerGame
      Player player1 = Player.fromJson(jsonDecode(_puzzle!.player1!));
      Player player2 = Player.fromJson(jsonDecode(_puzzle!.player2!));
      Player player3 = Player.fromJson(jsonDecode(_puzzle!.player3!));
      Player player4 = Player.fromJson(jsonDecode(_puzzle!.player4!));
      Player player5 = Player.fromJson(jsonDecode(_puzzle!.player5!));

      Player player1Unveiled = Player.fromJson(jsonDecode(_puzzle!.player1unveiled!));
      Player player2Unveiled = Player.fromJson(jsonDecode(_puzzle!.player2unveiled!));
      Player player3Unveiled = Player.fromJson(jsonDecode(_puzzle!.player3unveiled!));
      Player player4Unveiled = Player.fromJson(jsonDecode(_puzzle!.player4unveiled!));
      Player player5Unveiled = Player.fromJson(jsonDecode(_puzzle!.player5unveiled!));

      if (player1.pointsPerGame == player.pointsPerGame) {
        player1Unveiled.pointsPerGame = player.pointsPerGame;
        _puzzle!.player1unveiled = jsonEncode(player1Unveiled.toJson());
      }

      if (player2.pointsPerGame == player.pointsPerGame) {
        player2Unveiled.pointsPerGame = player.pointsPerGame;
        _puzzle!.player2unveiled = jsonEncode(player2Unveiled.toJson());
      }

      if (player3.pointsPerGame == player.pointsPerGame) {
        player3Unveiled.pointsPerGame = player.pointsPerGame;
        _puzzle!.player3unveiled = jsonEncode(player3Unveiled.toJson());
      }

      if (player4.pointsPerGame == player.pointsPerGame) {
        player4Unveiled.pointsPerGame = player.pointsPerGame;
        _puzzle!.player4unveiled = jsonEncode(player4Unveiled.toJson());
      }

      if (player5.pointsPerGame == player.pointsPerGame) {
        player5Unveiled.pointsPerGame = player.pointsPerGame;
        _puzzle!.player5unveiled = jsonEncode(player5Unveiled.toJson());
      }
    }

    _scaleAttrCards = false;

    // update hints
    _puzzle!.hints = _puzzle!.hints! - 1;

    // update game in session
    SingleModePuzzle temp = _puzzle!;
    _puzzle = null;
    _puzzle = temp;

    await secStorage.write(key: SharedPrefsConsts.gameInSession, value: jsonEncode(_puzzle!.toJson()));

    notifyListeners();
  }
}
