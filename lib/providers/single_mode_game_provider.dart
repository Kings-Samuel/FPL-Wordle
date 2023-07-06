import 'dart:convert';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/consts/appwrite_consts.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:fplwordle/helpers/utils/init_appwrite.dart';
import 'package:fplwordle/helpers/utils/init_sec_storage.dart';
import 'package:fplwordle/helpers/utils/navigator.dart';
import 'package:fplwordle/helpers/widgets/snack_bar_helper.dart';
import 'package:fplwordle/models/single_mode_puzzle.dart';
import 'package:fplwordle/providers/profile_provider.dart';
import 'package:fplwordle/providers/sound_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../consts/shared_prefs_consts.dart';
import '../helpers/widgets/custom_btn.dart';
import '../helpers/widgets/dialog_helper.dart';
import '../models/player.dart';
import '../models/profile.dart';
import 'keyboard_provider.dart';

class SingleModeGameProvider extends ChangeNotifier {
  String _error = '';
  Duration _durationUntilNextGame = Duration.zero;
  SingleModePuzzle? _puzzle;
  bool _scaleAttrCards = false;
  int _puzzleCardToAnimate = 0;
  int _lastUpdateTime = 0;
  List<Player> _players = []; // all players

  Duration get durationUntilNextGame => _durationUntilNextGame;
  SingleModePuzzle? get puzzle => _puzzle;
  String get error => _error;
  bool get scaleAttrCards => _scaleAttrCards;
  int get puzzleCardToAnimate => _puzzleCardToAnimate;
  int get lastUpdateTime => _lastUpdateTime;
  List<Player> get players => _players;

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
        await profileProvider.increaseGamesAbandonedCount();
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
        String allPlayersEncodedJSONstring = _puzzle!.allPlayersEncodedJSONstring!;
        _players = (jsonDecode(allPlayersEncodedJSONstring) as List<dynamic>)
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        final res = await database.getDocument(
            databaseId: AppwriteConsts.db, collectionId: AppwriteConsts.dailyPuzzle, documentId: yesterdayDocumentId);
        timesPlayed = res.data["timesPlayed"];
        _puzzle = SingleModePuzzle.fromJson(res.data);
        String allPlayersEncodedJSONstring = _puzzle!.allPlayersEncodedJSONstring!;
        _players = (jsonDecode(allPlayersEncodedJSONstring) as List<dynamic>)
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList();
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

      // lives (based on difficulty level)
      _puzzle!.lives = difficulty == 1
          ? 20
          : difficulty == 2
              ? 15
              : 10;
      // hints
      _puzzle!.hints = 3;

      // create playersUnveiled
      Player playerUnveiled = Player(
          firstName: "",
          secondName: "",
          webName: "",
          elementType: null,
          team: null,
          nowCost: null,
          totalPoints: null,
          bonus: null,
          goalsScored: null,
          assists: null,
          cleanSheets: null,
          goalsConceded: null,
          ownGoals: null,
          penaltiesMissed: null,
          yellowCards: null,
          redCards: null,
          starts: null,
          selectedByPercent: null,
          pointsPerGame: null,
          isUnveiled: false);
      String playerUnveiledEncoded = jsonEncode(playerUnveiled.toJson());
      _puzzle!.player1unveiled = _puzzle!.player2unveiled =
          _puzzle!.player3unveiled = _puzzle!.player4unveiled = _puzzle!.player5unveiled = playerUnveiledEncoded;

      // set score
      _puzzle!.score = 0;

      // first guess
      _puzzle!.isFirstGuessMade = false;

      // streak
      _puzzle!.streak = 0;

      //  save game in session
      await secStorage.write(key: SharedPrefsConsts.gameInSession, value: jsonEncode(_puzzle!.toJson()));

      // increase game count (timesPlayed)
      await database.updateDocument(
          databaseId: AppwriteConsts.db,
          collectionId: AppwriteConsts.dailyPuzzle,
          documentId: canLoadToday ? documentId : yesterdayDocumentId,
          data: {"timesPlayed": timesPlayed + 1});

      // increaseGamesPlayedCount
      if (context.mounted) context.read<ProfileProvider>().increaseGamesPlayedCount();

      notifyListeners();
    } on AppwriteException catch (e) {
      _error = e.message!;
      debugPrint(_error);
      snackBarHelper(context, message: _error, type: AnimatedSnackBarType.error);
    }
  }

  Future<void> loadGameInSession(BuildContext context) async {
    String? puzzleEncoded = await secStorage.read(key: SharedPrefsConsts.gameInSession);
    if (puzzleEncoded != null) {
      _puzzle = SingleModePuzzle.fromJson(jsonDecode(puzzleEncoded));
      String allPlayersEncodedJSONstring = _puzzle!.allPlayersEncodedJSONstring!;
      _players = (jsonDecode(allPlayersEncodedJSONstring) as List<dynamic>)
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList();

      if (_puzzle!.isFinished == true && context.mounted) {
        setGameComplete(context);
      }

      if (_puzzle!.lives! <= 0 && context.mounted) {
        setGameOver(context);
      }

      notifyListeners();
    }
  }

  void setScaleAttrIcons(bool value) {
    _scaleAttrCards = value;
    notifyListeners();
  }

  Future<void> animateUnveiledPuzzleCard(BuildContext context, int position) async {
    await context.read<SoundsProvider>().playCorrect();
    _puzzleCardToAnimate = position;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1000));
    _puzzleCardToAnimate = 0;
    notifyListeners();
  }

  Future<void> setPlayerUnveiled(BuildContext context, {required Player player, required int puzzlePosition}) async {
    // update player unveiled
    switch (puzzlePosition) {
      case 1:
        Player player1unveiled = Player.fromJson(jsonDecode(_puzzle!.player1unveiled!));
        player1unveiled.firstName = player.firstName;
        player1unveiled.secondName = player.secondName;
        player1unveiled.webName = player.webName;
        player1unveiled.isUnveiled = true;
        _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
      case 2:
        Player player2unveiled = Player.fromJson(jsonDecode(_puzzle!.player2unveiled!));
        player2unveiled.firstName = player.firstName;
        player2unveiled.secondName = player.secondName;
        player2unveiled.webName = player.webName;
        player2unveiled.isUnveiled = true;
        _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
      case 3:
        Player player3unveiled = Player.fromJson(jsonDecode(_puzzle!.player3unveiled!));
        player3unveiled.firstName = player.firstName;
        player3unveiled.secondName = player.secondName;
        player3unveiled.webName = player.webName;
        player3unveiled.isUnveiled = true;
        _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
      case 4:
        Player player4unveiled = Player.fromJson(jsonDecode(_puzzle!.player4unveiled!));
        player4unveiled.firstName = player.firstName;
        player4unveiled.secondName = player.secondName;
        player4unveiled.webName = player.webName;
        player4unveiled.isUnveiled = true;
        _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
      case 5:
        Player player5unveiled = Player.fromJson(jsonDecode(_puzzle!.player5unveiled!));
        player5unveiled.firstName = player.firstName;
        player5unveiled.secondName = player.secondName;
        player5unveiled.webName = player.webName;
        player5unveiled.isUnveiled = true;
        _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
        break;
      default:
    }

    // increase score
    _puzzle!.score = _puzzle!.score! + 5;

    // update game in session
    await secStorage.write(key: SharedPrefsConsts.gameInSession, value: jsonEncode(_puzzle!.toJson()));

    if (context.mounted) animateUnveiledPuzzleCard(context, puzzlePosition);
  }

  void setGameComplete(BuildContext context, {bool? shouldNotifyListeners}) {
    context.read<SoundsProvider>().playCheer();
    if (_puzzle!.isFinished != true) {
      // add bonus scores
      _puzzle!.score = _puzzle!.score! + getHintBonus() + getLifeBonus(context);
      // increment games won count
      context.read<ProfileProvider>().increaseGamesWonCount();
      // increase xp
      context.read<ProfileProvider>().increaseXP(_puzzle!.score!);
      // set highscore
      if (_puzzle!.score! > context.read<ProfileProvider>().profile!.highScore!) {
        context.read<ProfileProvider>().setHighScore(_puzzle!.score!);
      }
      // update no hints used
    }
    _puzzle!.isFinished = true;
    secStorage.write(key: SharedPrefsConsts.gameInSession, value: jsonEncode(_puzzle!.toJson()));
    if (shouldNotifyListeners == true) notifyListeners();
  }

  void setGameOver(BuildContext context) {
    if (_puzzle!.isGameOver != true) {
      _puzzle!.isGameOver = true;
      context.read<ProfileProvider>().increaseGamesLostCount();
    }

    // play gameover sound
    context.read<SoundsProvider>().playGameOver();
    // show gameover dialog
    customDialog(context: context, barrierDismissible: false, title: "GAME OVER!", contentList: [
      // game over gif
      Container(
        height: 200,
        width: 200,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/gameover.gif"),
            fit: BoxFit.cover,
          ),
        ),
      ),
      // play again btn
      Shimmer(
        color: Colors.white,
        colorOpacity: 0.45,
        child: SizedBox(
            width: 300,
            child: SizedBox(
                height: 40,
                width: 150,
                child: customButton(context,
                    useSound: false,
                    backgroundColor: Colors.green,
                    icon: Icons.replay,
                    text: "Play Again",
                    onTap: () {}))),
      ),
      const SizedBox(height: 20),
      // back btn
      Shimmer(
        color: Colors.white,
        colorOpacity: 0.45,
        child: SizedBox(
            width: 300,
            child: SizedBox(
                height: 40,
                width: 150,
                child: customButton(context,
                    backgroundColor: Palette.primary,
                    icon: Icons.arrow_back_ios,
                    text: "Go back",
                    useSound: false, onTap: () {
                  popNavigator(context, rootNavigator: true);
                  popNavigator(context);
                }))),
      ),
      //! for testing purposes only - clear game in session btn
      if (kDebugMode)
        Column(
          children: [
            const SizedBox(height: 20),
            // clear game in session btn
            SizedBox(
              width: 300,
              child: customButton(context,
                  backgroundColor: Colors.red, icon: Icons.close, text: "Clear Game In Session", onTap: () async {
                await secStorage.delete(key: "gameInSession");
                await secStorage.delete(key: "lastGameId");
              }),
            ),
            const SizedBox(height: 20),
            // add more lives btn
            SizedBox(
              width: 300,
              child: customButton(context, backgroundColor: Colors.blue, icon: Icons.close, text: "Add 3 lives",
                  onTap: () async {
                _puzzle!.lives = _puzzle!.lives! + 3;
                await secStorage.write(key: "gameInSession", value: jsonEncode(_puzzle!.toJson()));
                notifyListeners();
                if (context.mounted) popNavigator(context, rootNavigator: true);
              }),
            ),
          ],
        )
    ]);
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

    _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

    await secStorage.write(key: SharedPrefsConsts.gameInSession, value: jsonEncode(_puzzle!.toJson()));

    notifyListeners();
  }

  Future<void> guessPlayer(BuildContext context, String guess) async {
    if (_puzzle!.lives! > 0) {
      bool isGuessRight = false;
      bool isAnyMatchFound = false;
      List<String> selectedAttributes = _puzzle!.selectedAttributes!;

      Player player1 = Player.fromJson(jsonDecode(_puzzle!.player1!));
      Player player2 = Player.fromJson(jsonDecode(_puzzle!.player2!));
      Player player3 = Player.fromJson(jsonDecode(_puzzle!.player3!));
      Player player4 = Player.fromJson(jsonDecode(_puzzle!.player4!));
      Player player5 = Player.fromJson(jsonDecode(_puzzle!.player5!));

      Player player1unveiled = Player.fromJson(jsonDecode(_puzzle!.player1unveiled!));
      Player player2unveiled = Player.fromJson(jsonDecode(_puzzle!.player2unveiled!));
      Player player3unveiled = Player.fromJson(jsonDecode(_puzzle!.player3unveiled!));
      Player player4unveiled = Player.fromJson(jsonDecode(_puzzle!.player4unveiled!));
      Player player5unveiled = Player.fromJson(jsonDecode(_puzzle!.player5unveiled!));

      // ** find macthing player ** //
      if (guess.trim() == "${player1.firstName} ${player1.secondName}".trim()) {
        isGuessRight = true;
        isAnyMatchFound = true;
        player1unveiled = player1;
        player1unveiled.isUnveiled = true;
        _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
        snackBarHelper(context, message: "Player found: $guess");
        animateUnveiledPuzzleCard(context, 1);

        // handle matching team
        if (player1.team == player2.team && player2unveiled.team != player1.team) {
          player2unveiled.team = player1.team;
          _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
        }
        if (player1.team == player3.team && player3unveiled.team != player1.team) {
          player3unveiled.team = player1.team;
          _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
        }
        if (player1.team == player4.team && player4unveiled.team != player1.team) {
          player4unveiled.team = player1.team;
          _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
        }
        if (player1.team == player5.team && player5unveiled.team != player1.team) {
          player5unveiled.team = player1.team;
          _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
        }

        // find other matching traits
        if (selectedAttributes.contains("totalPoints")) {
          if (player1.totalPoints == player2.totalPoints && player2unveiled.totalPoints != player1.totalPoints) {
            player2unveiled.totalPoints = player1.totalPoints;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player1.totalPoints == player3.totalPoints && player3unveiled.totalPoints != player1.totalPoints) {
            player3unveiled.totalPoints = player1.totalPoints;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player1.totalPoints == player4.totalPoints && player4unveiled.totalPoints != player1.totalPoints) {
            player4unveiled.totalPoints = player1.totalPoints;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player1.totalPoints == player5.totalPoints && player5unveiled.totalPoints != player1.totalPoints) {
            player5unveiled.totalPoints = player1.totalPoints;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("bonus")) {
          if (player1.bonus == player2.bonus && player2unveiled.bonus != player1.bonus) {
            player2unveiled.bonus = player1.bonus;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player1.bonus == player3.bonus && player3unveiled.bonus != player1.bonus) {
            player3unveiled.bonus = player1.bonus;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player1.bonus == player4.bonus && player4unveiled.bonus != player1.bonus) {
            player4unveiled.bonus = player1.bonus;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player1.bonus == player5.bonus && player5unveiled.bonus != player1.bonus) {
            player5unveiled.bonus = player1.bonus;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("goalsScored")) {
          if (player1.goalsScored == player2.goalsScored && player2unveiled.goalsScored != player1.goalsScored) {
            player2unveiled.goalsScored = player1.goalsScored;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player1.goalsScored == player3.goalsScored && player3unveiled.goalsScored != player1.goalsScored) {
            player3unveiled.goalsScored = player1.goalsScored;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player1.goalsScored == player4.goalsScored && player4unveiled.goalsScored != player1.goalsScored) {
            player4unveiled.goalsScored = player1.goalsScored;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player1.goalsScored == player5.goalsScored && player5unveiled.goalsScored != player1.goalsScored) {
            player5unveiled.goalsScored = player1.goalsScored;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("assists")) {
          if (player1.assists == player2.assists && player2unveiled.assists != player1.assists) {
            player2unveiled.assists = player1.assists;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player1.assists == player3.assists && player3unveiled.assists != player1.assists) {
            player3unveiled.assists = player1.assists;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player1.assists == player4.assists && player4unveiled.assists != player1.assists) {
            player4unveiled.assists = player1.assists;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player1.assists == player5.assists && player5unveiled.assists != player1.assists) {
            player5unveiled.assists = player1.assists;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("cleanSheets")) {
          if (player1.cleanSheets == player2.cleanSheets && player2unveiled.cleanSheets != player1.cleanSheets) {
            player2unveiled.cleanSheets = player1.cleanSheets;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player1.cleanSheets == player3.cleanSheets && player3unveiled.cleanSheets != player1.cleanSheets) {
            player3unveiled.cleanSheets = player1.cleanSheets;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player1.cleanSheets == player4.cleanSheets && player4unveiled.cleanSheets != player1.cleanSheets) {
            player4unveiled.cleanSheets = player1.cleanSheets;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player1.cleanSheets == player5.cleanSheets && player5unveiled.cleanSheets != player1.cleanSheets) {
            player5unveiled.cleanSheets = player1.cleanSheets;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("goalsConceded")) {
          if (player1.goalsConceded == player2.goalsConceded &&
              player2unveiled.goalsConceded != player1.goalsConceded) {
            player2unveiled.goalsConceded = player1.goalsConceded;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player1.goalsConceded == player3.goalsConceded &&
              player3unveiled.goalsConceded != player1.goalsConceded) {
            player3unveiled.goalsConceded = player1.goalsConceded;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player1.goalsConceded == player4.goalsConceded &&
              player4unveiled.goalsConceded != player1.goalsConceded) {
            player4unveiled.goalsConceded = player1.goalsConceded;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player1.goalsConceded == player5.goalsConceded &&
              player5unveiled.goalsConceded != player1.goalsConceded) {
            player5unveiled.goalsConceded = player1.goalsConceded;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("ownGoals")) {
          if (player1.ownGoals == player2.ownGoals && player2unveiled.ownGoals != player1.ownGoals) {
            player2unveiled.ownGoals = player1.ownGoals;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player1.ownGoals == player3.ownGoals && player3unveiled.ownGoals != player1.ownGoals) {
            player3unveiled.ownGoals = player1.ownGoals;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player1.ownGoals == player4.ownGoals && player4unveiled.ownGoals != player1.ownGoals) {
            player4unveiled.ownGoals = player1.ownGoals;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player1.ownGoals == player5.ownGoals && player5unveiled.ownGoals != player1.ownGoals) {
            player5unveiled.ownGoals = player1.ownGoals;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("penaltiesMissed")) {
          if (player1.penaltiesMissed == player2.penaltiesMissed &&
              player2unveiled.penaltiesMissed != player1.penaltiesMissed) {
            player2unveiled.penaltiesMissed = player1.penaltiesMissed;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player1.penaltiesMissed == player3.penaltiesMissed &&
              player3unveiled.penaltiesMissed != player1.penaltiesMissed) {
            player3unveiled.penaltiesMissed = player1.penaltiesMissed;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player1.penaltiesMissed == player4.penaltiesMissed &&
              player4unveiled.penaltiesMissed != player1.penaltiesMissed) {
            player4unveiled.penaltiesMissed = player1.penaltiesMissed;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player1.penaltiesMissed == player5.penaltiesMissed &&
              player5unveiled.penaltiesMissed != player1.penaltiesMissed) {
            player5unveiled.penaltiesMissed = player1.penaltiesMissed;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("yellowCards")) {
          if (player1.yellowCards == player2.yellowCards && player2unveiled.yellowCards != player1.yellowCards) {
            player2unveiled.yellowCards = player1.yellowCards;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player1.yellowCards == player3.yellowCards && player3unveiled.yellowCards != player1.yellowCards) {
            player3unveiled.yellowCards = player1.yellowCards;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player1.yellowCards == player4.yellowCards && player4unveiled.yellowCards != player1.yellowCards) {
            player4unveiled.yellowCards = player1.yellowCards;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player1.yellowCards == player5.yellowCards && player5unveiled.yellowCards != player1.yellowCards) {
            player5unveiled.yellowCards = player1.yellowCards;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("redCards")) {
          if (player1.redCards == player2.redCards && player2unveiled.redCards != player1.redCards) {
            player2unveiled.redCards = player1.redCards;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player1.redCards == player3.redCards && player3unveiled.redCards != player1.redCards) {
            player3unveiled.redCards = player1.redCards;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player1.redCards == player4.redCards && player4unveiled.redCards != player1.redCards) {
            player4unveiled.redCards = player1.redCards;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player1.redCards == player5.redCards && player5unveiled.redCards != player1.redCards) {
            player5unveiled.redCards = player1.redCards;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("starts")) {
          if (player1.starts == player2.starts && player2unveiled.starts != player1.starts) {
            player2unveiled.starts = player1.starts;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player1.starts == player3.starts && player3unveiled.starts != player1.starts) {
            player3unveiled.starts = player1.starts;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player1.starts == player4.starts && player4unveiled.starts != player1.starts) {
            player4unveiled.starts = player1.starts;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player1.starts == player5.starts && player5unveiled.starts != player1.starts) {
            player5unveiled.starts = player1.starts;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("pointsPerGame")) {
          if (player1.pointsPerGame == player2.pointsPerGame &&
              player2unveiled.pointsPerGame != player1.pointsPerGame) {
            player2unveiled.pointsPerGame = player1.pointsPerGame;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player1.pointsPerGame == player3.pointsPerGame &&
              player3unveiled.pointsPerGame != player1.pointsPerGame) {
            player3unveiled.pointsPerGame = player1.pointsPerGame;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player1.pointsPerGame == player4.pointsPerGame &&
              player4unveiled.pointsPerGame != player1.pointsPerGame) {
            player4unveiled.pointsPerGame = player1.pointsPerGame;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player1.pointsPerGame == player5.pointsPerGame &&
              player5unveiled.pointsPerGame != player1.pointsPerGame) {
            player5unveiled.pointsPerGame = player1.pointsPerGame;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }
      } else if (guess == "${player2.firstName} ${player2.secondName}") {
        isGuessRight = true;
        isAnyMatchFound = true;
        player2unveiled = player2;
        player2unveiled.isUnveiled = true;
        _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
        snackBarHelper(context, message: "Player found: $guess");
        animateUnveiledPuzzleCard(context, 2);

        // handle matching team
        if (player2.team == player1.team && player1unveiled.team != player2.team) {
          player1unveiled.team = player2.team;
          _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
        }
        if (player2.team == player3.team && player3unveiled.team != player2.team) {
          player3unveiled.team = player2.team;
          _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
        }
        if (player2.team == player4.team && player4unveiled.team != player2.team) {
          player4unveiled.team = player2.team;
          _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
        }
        if (player2.team == player5.team && player5unveiled.team != player2.team) {
          player5unveiled.team = player2.team;
          _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
        }

        // find other matching traits
        if (selectedAttributes.contains("totalPoints")) {
          if (player2.totalPoints == player1.totalPoints && player1unveiled.totalPoints != player2.totalPoints) {
            player1unveiled.totalPoints = player2.totalPoints;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player2.totalPoints == player3.totalPoints && player3unveiled.totalPoints != player2.totalPoints) {
            player3unveiled.totalPoints = player2.totalPoints;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player2.totalPoints == player4.totalPoints && player4unveiled.totalPoints != player2.totalPoints) {
            player4unveiled.totalPoints = player2.totalPoints;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player2.totalPoints == player5.totalPoints && player5unveiled.totalPoints != player2.totalPoints) {
            player5unveiled.totalPoints = player2.totalPoints;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("bonus")) {
          if (player2.bonus == player1.bonus && player1unveiled.bonus != player2.bonus) {
            player1unveiled.bonus = player2.bonus;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player2.bonus == player3.bonus && player3unveiled.bonus != player2.bonus) {
            player3unveiled.bonus = player2.bonus;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player2.bonus == player4.bonus && player4unveiled.bonus != player2.bonus) {
            player4unveiled.bonus = player2.bonus;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player2.bonus == player5.bonus && player5unveiled.bonus != player2.bonus) {
            player5unveiled.bonus = player2.bonus;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("goalsScored")) {
          if (player2.goalsScored == player1.goalsScored && player1unveiled.goalsScored != player2.goalsScored) {
            player1unveiled.goalsScored = player2.goalsScored;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player2.goalsScored == player3.goalsScored && player3unveiled.goalsScored != player2.goalsScored) {
            player3unveiled.goalsScored = player2.goalsScored;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player2.goalsScored == player4.goalsScored && player4unveiled.goalsScored != player2.goalsScored) {
            player4unveiled.goalsScored = player2.goalsScored;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player2.goalsScored == player5.goalsScored && player5unveiled.goalsScored != player2.goalsScored) {
            player5unveiled.goalsScored = player2.goalsScored;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("assists")) {
          if (player2.assists == player1.assists && player1unveiled.assists != player2.assists) {
            player1unveiled.assists = player2.assists;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player2.assists == player3.assists && player3unveiled.assists != player2.assists) {
            player3unveiled.assists = player2.assists;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player2.assists == player4.assists && player4unveiled.assists != player2.assists) {
            player4unveiled.assists = player2.assists;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player2.assists == player5.assists && player5unveiled.assists != player2.assists) {
            player5unveiled.assists = player2.assists;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("cleanSheets")) {
          if (player2.cleanSheets == player1.cleanSheets && player1unveiled.cleanSheets != player2.cleanSheets) {
            player1unveiled.cleanSheets = player2.cleanSheets;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player2.cleanSheets == player3.cleanSheets && player3unveiled.cleanSheets != player2.cleanSheets) {
            player3unveiled.cleanSheets = player2.cleanSheets;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player2.cleanSheets == player4.cleanSheets && player4unveiled.cleanSheets != player2.cleanSheets) {
            player4unveiled.cleanSheets = player2.cleanSheets;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player2.cleanSheets == player5.cleanSheets && player5unveiled.cleanSheets != player2.cleanSheets) {
            player5unveiled.cleanSheets = player2.cleanSheets;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("goalsConceded")) {
          if (player2.goalsConceded == player1.goalsConceded &&
              player1unveiled.goalsConceded != player2.goalsConceded) {
            player1unveiled.goalsConceded = player2.goalsConceded;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player2.goalsConceded == player3.goalsConceded &&
              player3unveiled.goalsConceded != player2.goalsConceded) {
            player3unveiled.goalsConceded = player2.goalsConceded;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player2.goalsConceded == player4.goalsConceded &&
              player4unveiled.goalsConceded != player2.goalsConceded) {
            player4unveiled.goalsConceded = player2.goalsConceded;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player2.goalsConceded == player5.goalsConceded &&
              player5unveiled.goalsConceded != player2.goalsConceded) {
            player5unveiled.goalsConceded = player2.goalsConceded;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("ownGoals")) {
          if (player2.ownGoals == player1.ownGoals && player1unveiled.ownGoals != player2.ownGoals) {
            player1unveiled.ownGoals = player2.ownGoals;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player2.ownGoals == player3.ownGoals && player3unveiled.ownGoals != player2.ownGoals) {
            player3unveiled.ownGoals = player2.ownGoals;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player2.ownGoals == player4.ownGoals && player4unveiled.ownGoals != player2.ownGoals) {
            player4unveiled.ownGoals = player2.ownGoals;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player2.ownGoals == player5.ownGoals && player5unveiled.ownGoals != player2.ownGoals) {
            player5unveiled.ownGoals = player2.ownGoals;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("penaltiesMissed")) {
          if (player2.penaltiesMissed == player1.penaltiesMissed &&
              player1unveiled.penaltiesMissed != player2.penaltiesMissed) {
            player1unveiled.penaltiesMissed = player2.penaltiesMissed;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player2.penaltiesMissed == player3.penaltiesMissed &&
              player3unveiled.penaltiesMissed != player2.penaltiesMissed) {
            player3unveiled.penaltiesMissed = player2.penaltiesMissed;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player2.penaltiesMissed == player4.penaltiesMissed &&
              player4unveiled.penaltiesMissed != player2.penaltiesMissed) {
            player4unveiled.penaltiesMissed = player2.penaltiesMissed;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player2.penaltiesMissed == player5.penaltiesMissed &&
              player5unveiled.penaltiesMissed != player2.penaltiesMissed) {
            player5unveiled.penaltiesMissed = player2.penaltiesMissed;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("yellowCards")) {
          if (player2.yellowCards == player1.yellowCards && player1unveiled.yellowCards != player2.yellowCards) {
            player1unveiled.yellowCards = player2.yellowCards;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player2.yellowCards == player3.yellowCards && player3unveiled.yellowCards != player2.yellowCards) {
            player3unveiled.yellowCards = player2.yellowCards;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player2.yellowCards == player4.yellowCards && player4unveiled.yellowCards != player2.yellowCards) {
            player4unveiled.yellowCards = player2.yellowCards;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player2.yellowCards == player5.yellowCards && player5unveiled.yellowCards != player2.yellowCards) {
            player5unveiled.yellowCards = player2.yellowCards;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("redCards")) {
          if (player2.redCards == player1.redCards && player1unveiled.redCards != player2.redCards) {
            player1unveiled.redCards = player2.redCards;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player2.redCards == player3.redCards && player3unveiled.redCards != player2.redCards) {
            player3unveiled.redCards = player2.redCards;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player2.redCards == player4.redCards && player4unveiled.redCards != player2.redCards) {
            player4unveiled.redCards = player2.redCards;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player2.redCards == player5.redCards && player5unveiled.redCards != player2.redCards) {
            player5unveiled.redCards = player2.redCards;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("starts")) {
          if (player2.starts == player1.starts && player1unveiled.starts != player2.starts) {
            player1unveiled.starts = player2.starts;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player2.starts == player3.starts && player3unveiled.starts != player2.starts) {
            player3unveiled.starts = player2.starts;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player2.starts == player4.starts && player4unveiled.starts != player2.starts) {
            player4unveiled.starts = player2.starts;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player2.starts == player5.starts && player5unveiled.starts != player2.starts) {
            player5unveiled.starts = player2.starts;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("pointsPerGame")) {
          if (player2.pointsPerGame == player1.pointsPerGame &&
              player1unveiled.pointsPerGame != player2.pointsPerGame) {
            player1unveiled.pointsPerGame = player2.pointsPerGame;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player2.pointsPerGame == player3.pointsPerGame &&
              player3unveiled.pointsPerGame != player2.pointsPerGame) {
            player3unveiled.pointsPerGame = player2.pointsPerGame;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player2.pointsPerGame == player4.pointsPerGame &&
              player4unveiled.pointsPerGame != player2.pointsPerGame) {
            player4unveiled.pointsPerGame = player2.pointsPerGame;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player2.pointsPerGame == player5.pointsPerGame &&
              player5unveiled.pointsPerGame != player2.pointsPerGame) {
            player5unveiled.pointsPerGame = player2.pointsPerGame;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }
      } else if (guess == "${player3.firstName} ${player3.secondName}") {
        isGuessRight = true;
        isAnyMatchFound = true;
        player3unveiled = player3;
        player3unveiled.isUnveiled = true;
        _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
        snackBarHelper(context, message: "Player found: $guess");
        animateUnveiledPuzzleCard(context, 3);

        // handle matching team
        if (player3.team == player1.team && player1unveiled.team != player3.team) {
          player1unveiled.team = player3.team;
          _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
        }
        if (player3.team == player2.team && player2unveiled.team != player3.team) {
          player2unveiled.team = player3.team;
          _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
        }
        if (player3.team == player4.team && player4unveiled.team != player3.team) {
          player4unveiled.team = player3.team;
          _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
        }
        if (player3.team == player5.team && player5unveiled.team != player3.team) {
          player5unveiled.team = player3.team;
          _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
        }

        // find other matching traits
        if (selectedAttributes.contains("totalPoints")) {
          if (player3.totalPoints == player1.totalPoints && player1unveiled.totalPoints != player3.totalPoints) {
            player1unveiled.totalPoints = player3.totalPoints;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player3.totalPoints == player2.totalPoints && player2unveiled.totalPoints != player3.totalPoints) {
            player2unveiled.totalPoints = player3.totalPoints;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player3.totalPoints == player4.totalPoints && player4unveiled.totalPoints != player3.totalPoints) {
            player4unveiled.totalPoints = player3.totalPoints;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player3.totalPoints == player5.totalPoints && player5unveiled.totalPoints != player3.totalPoints) {
            player5unveiled.totalPoints = player3.totalPoints;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("bonus")) {
          if (player3.bonus == player1.bonus && player1unveiled.bonus != player3.bonus) {
            player1unveiled.bonus = player3.bonus;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player3.bonus == player2.bonus && player2unveiled.bonus != player3.bonus) {
            player2unveiled.bonus = player3.bonus;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player3.bonus == player4.bonus && player4unveiled.bonus != player3.bonus) {
            player4unveiled.bonus = player3.bonus;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player3.bonus == player5.bonus && player5unveiled.bonus != player3.bonus) {
            player5unveiled.bonus = player3.bonus;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("goalsScored")) {
          if (player3.goalsScored == player1.goalsScored && player1unveiled.goalsScored != player3.goalsScored) {
            player1unveiled.goalsScored = player3.goalsScored;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player3.goalsScored == player2.goalsScored && player2unveiled.goalsScored != player3.goalsScored) {
            player2unveiled.goalsScored = player3.goalsScored;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player3.goalsScored == player4.goalsScored && player4unveiled.goalsScored != player3.goalsScored) {
            player4unveiled.goalsScored = player3.goalsScored;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player3.goalsScored == player5.goalsScored && player5unveiled.goalsScored != player3.goalsScored) {
            player5unveiled.goalsScored = player3.goalsScored;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("assists")) {
          if (player3.assists == player1.assists && player1unveiled.assists != player3.assists) {
            player1unveiled.assists = player3.assists;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player3.assists == player2.assists && player2unveiled.assists != player3.assists) {
            player2unveiled.assists = player3.assists;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player3.assists == player4.assists && player4unveiled.assists != player3.assists) {
            player4unveiled.assists = player3.assists;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player3.assists == player5.assists && player5unveiled.assists != player3.assists) {
            player5unveiled.assists = player3.assists;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("cleanSheets")) {
          if (player3.cleanSheets == player1.cleanSheets && player1unveiled.cleanSheets != player3.cleanSheets) {
            player1unveiled.cleanSheets = player3.cleanSheets;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player3.cleanSheets == player2.cleanSheets && player2unveiled.cleanSheets != player3.cleanSheets) {
            player2unveiled.cleanSheets = player3.cleanSheets;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player3.cleanSheets == player4.cleanSheets && player4unveiled.cleanSheets != player3.cleanSheets) {
            player4unveiled.cleanSheets = player3.cleanSheets;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player3.cleanSheets == player5.cleanSheets && player5unveiled.cleanSheets != player3.cleanSheets) {
            player5unveiled.cleanSheets = player3.cleanSheets;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("goalsConceded")) {
          if (player3.goalsConceded == player1.goalsConceded &&
              player1unveiled.goalsConceded != player3.goalsConceded) {
            player1unveiled.goalsConceded = player3.goalsConceded;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player3.goalsConceded == player2.goalsConceded &&
              player2unveiled.goalsConceded != player3.goalsConceded) {
            player2unveiled.goalsConceded = player3.goalsConceded;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player3.goalsConceded == player4.goalsConceded &&
              player4unveiled.goalsConceded != player3.goalsConceded) {
            player4unveiled.goalsConceded = player3.goalsConceded;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player3.goalsConceded == player5.goalsConceded &&
              player5unveiled.goalsConceded != player3.goalsConceded) {
            player5unveiled.goalsConceded = player3.goalsConceded;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("ownGoals")) {
          if (player3.ownGoals == player1.ownGoals && player1unveiled.ownGoals != player3.ownGoals) {
            player1unveiled.ownGoals = player3.ownGoals;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player3.ownGoals == player2.ownGoals && player2unveiled.ownGoals != player3.ownGoals) {
            player2unveiled.ownGoals = player3.ownGoals;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player3.ownGoals == player4.ownGoals && player4unveiled.ownGoals != player3.ownGoals) {
            player4unveiled.ownGoals = player3.ownGoals;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player3.ownGoals == player5.ownGoals && player5unveiled.ownGoals != player3.ownGoals) {
            player5unveiled.ownGoals = player3.ownGoals;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("penaltiesMissed")) {
          if (player3.penaltiesMissed == player1.penaltiesMissed &&
              player1unveiled.penaltiesMissed != player3.penaltiesMissed) {
            player1unveiled.penaltiesMissed = player3.penaltiesMissed;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player3.penaltiesMissed == player2.penaltiesMissed &&
              player2unveiled.penaltiesMissed != player3.penaltiesMissed) {
            player2unveiled.penaltiesMissed = player3.penaltiesMissed;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player3.penaltiesMissed == player4.penaltiesMissed &&
              player4unveiled.penaltiesMissed != player3.penaltiesMissed) {
            player4unveiled.penaltiesMissed = player3.penaltiesMissed;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player3.penaltiesMissed == player5.penaltiesMissed &&
              player5unveiled.penaltiesMissed != player3.penaltiesMissed) {
            player5unveiled.penaltiesMissed = player3.penaltiesMissed;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("yellowCards")) {
          if (player3.yellowCards == player1.yellowCards && player1unveiled.yellowCards != player3.yellowCards) {
            player1unveiled.yellowCards = player3.yellowCards;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player3.yellowCards == player2.yellowCards && player2unveiled.yellowCards != player3.yellowCards) {
            player2unveiled.yellowCards = player3.yellowCards;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player3.yellowCards == player4.yellowCards && player4unveiled.yellowCards != player3.yellowCards) {
            player4unveiled.yellowCards = player3.yellowCards;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player3.yellowCards == player5.yellowCards && player5unveiled.yellowCards != player3.yellowCards) {
            player5unveiled.yellowCards = player3.yellowCards;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("redCards")) {
          if (player3.redCards == player1.redCards && player1unveiled.redCards != player3.redCards) {
            player1unveiled.redCards = player3.redCards;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player3.redCards == player2.redCards && player2unveiled.redCards != player3.redCards) {
            player2unveiled.redCards = player3.redCards;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player3.redCards == player4.redCards && player4unveiled.redCards != player3.redCards) {
            player4unveiled.redCards = player3.redCards;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player3.redCards == player5.redCards && player5unveiled.redCards != player3.redCards) {
            player5unveiled.redCards = player3.redCards;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("starts")) {
          if (player3.starts == player1.starts && player1unveiled.starts != player3.starts) {
            player1unveiled.starts = player3.starts;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player3.starts == player2.starts && player2unveiled.starts != player3.starts) {
            player2unveiled.starts = player3.starts;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player3.starts == player4.starts && player4unveiled.starts != player3.starts) {
            player4unveiled.starts = player3.starts;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player3.starts == player5.starts && player5unveiled.starts != player3.starts) {
            player5unveiled.starts = player3.starts;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("pointsPerGame")) {
          if (player3.pointsPerGame == player1.pointsPerGame &&
              player1unveiled.pointsPerGame != player3.pointsPerGame) {
            player1unveiled.pointsPerGame = player3.pointsPerGame;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player3.pointsPerGame == player2.pointsPerGame &&
              player2unveiled.pointsPerGame != player3.pointsPerGame) {
            player2unveiled.pointsPerGame = player3.pointsPerGame;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player3.pointsPerGame == player4.pointsPerGame &&
              player4unveiled.pointsPerGame != player3.pointsPerGame) {
            player4unveiled.pointsPerGame = player3.pointsPerGame;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player3.pointsPerGame == player5.pointsPerGame &&
              player5unveiled.pointsPerGame != player3.pointsPerGame) {
            player5unveiled.pointsPerGame = player3.pointsPerGame;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }
      } else if (guess == "${player4.firstName} ${player4.secondName}") {
        isGuessRight = true;
        isAnyMatchFound = true;
        player4unveiled = player4;
        player4unveiled.isUnveiled = true;
        _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
        snackBarHelper(context, message: "Player found: $guess");
        animateUnveiledPuzzleCard(context, 4);

        // handle matching team
        if (player4.team == player1.team && player1unveiled.team != player4.team) {
          player1unveiled.team = player4.team;
          _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
        }

        if (player4.team == player2.team && player2unveiled.team != player4.team) {
          player2unveiled.team = player4.team;
          _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
        }

        if (player4.team == player3.team && player3unveiled.team != player4.team) {
          player3unveiled.team = player4.team;
          _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
        }

        if (player4.team == player5.team && player5unveiled.team != player4.team) {
          player5unveiled.team = player4.team;
          _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
        }

        // handle matching position
        if (selectedAttributes.contains("totalPoints")) {
          if (player4.totalPoints == player1.totalPoints && player1unveiled.totalPoints != player4.totalPoints) {
            player1unveiled.totalPoints = player4.totalPoints;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player4.totalPoints == player2.totalPoints && player2unveiled.totalPoints != player4.totalPoints) {
            player2unveiled.totalPoints = player4.totalPoints;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player4.totalPoints == player3.totalPoints && player4unveiled.totalPoints != player3.totalPoints) {
            player4unveiled.totalPoints = player4.totalPoints;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player4.totalPoints == player5.totalPoints && player5unveiled.totalPoints != player4.totalPoints) {
            player5unveiled.totalPoints = player4.totalPoints;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("bonus")) {
          if (player4.bonus == player1.bonus && player1unveiled.bonus != player4.bonus) {
            player1unveiled.bonus = player4.bonus;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player4.bonus == player2.bonus && player2unveiled.bonus != player4.bonus) {
            player2unveiled.bonus = player4.bonus;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player4.bonus == player3.bonus && player4unveiled.bonus != player3.bonus) {
            player4unveiled.bonus = player4.bonus;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player4.bonus == player5.bonus && player5unveiled.bonus != player4.bonus) {
            player5unveiled.bonus = player4.bonus;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("assists")) {
          if (player4.assists == player1.assists && player1unveiled.assists != player4.assists) {
            player1unveiled.assists = player4.assists;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player4.assists == player2.assists && player2unveiled.assists != player4.assists) {
            player2unveiled.assists = player4.assists;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player4.assists == player3.assists && player4unveiled.assists != player3.assists) {
            player4unveiled.assists = player4.assists;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player4.assists == player5.assists && player5unveiled.assists != player4.assists) {
            player5unveiled.assists = player4.assists;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("cleanSheets")) {
          if (player4.cleanSheets == player1.cleanSheets && player1unveiled.cleanSheets != player4.cleanSheets) {
            player1unveiled.cleanSheets = player4.cleanSheets;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player4.cleanSheets == player2.cleanSheets && player2unveiled.cleanSheets != player4.cleanSheets) {
            player2unveiled.cleanSheets = player4.cleanSheets;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player4.cleanSheets == player3.cleanSheets && player4unveiled.cleanSheets != player3.cleanSheets) {
            player4unveiled.cleanSheets = player4.cleanSheets;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player4.cleanSheets == player5.cleanSheets && player5unveiled.cleanSheets != player4.cleanSheets) {
            player5unveiled.cleanSheets = player4.cleanSheets;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("goalsConceded")) {
          if (player4.goalsConceded == player1.goalsConceded &&
              player1unveiled.goalsConceded != player4.goalsConceded) {
            player1unveiled.goalsConceded = player4.goalsConceded;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player4.goalsConceded == player2.goalsConceded &&
              player2unveiled.goalsConceded != player4.goalsConceded) {
            player2unveiled.goalsConceded = player4.goalsConceded;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player4.goalsConceded == player3.goalsConceded &&
              player4unveiled.goalsConceded != player3.goalsConceded) {
            player4unveiled.goalsConceded = player4.goalsConceded;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player4.goalsConceded == player5.goalsConceded &&
              player5unveiled.goalsConceded != player4.goalsConceded) {
            player5unveiled.goalsConceded = player4.goalsConceded;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("ownGoals")) {
          if (player4.ownGoals == player1.ownGoals && player1unveiled.ownGoals != player4.ownGoals) {
            player1unveiled.ownGoals = player4.ownGoals;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player4.ownGoals == player2.ownGoals && player2unveiled.ownGoals != player4.ownGoals) {
            player2unveiled.ownGoals = player4.ownGoals;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player4.ownGoals == player3.ownGoals && player4unveiled.ownGoals != player3.ownGoals) {
            player4unveiled.ownGoals = player4.ownGoals;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player4.ownGoals == player5.ownGoals && player5unveiled.ownGoals != player4.ownGoals) {
            player5unveiled.ownGoals = player4.ownGoals;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("penaltiesMissed")) {
          if (player4.penaltiesMissed == player1.penaltiesMissed &&
              player1unveiled.penaltiesMissed != player4.penaltiesMissed) {
            player1unveiled.penaltiesMissed = player4.penaltiesMissed;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player4.penaltiesMissed == player2.penaltiesMissed &&
              player2unveiled.penaltiesMissed != player4.penaltiesMissed) {
            player2unveiled.penaltiesMissed = player4.penaltiesMissed;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player4.penaltiesMissed == player3.penaltiesMissed &&
              player4unveiled.penaltiesMissed != player3.penaltiesMissed) {
            player4unveiled.penaltiesMissed = player4.penaltiesMissed;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player4.penaltiesMissed == player5.penaltiesMissed &&
              player5unveiled.penaltiesMissed != player4.penaltiesMissed) {
            player5unveiled.penaltiesMissed = player4.penaltiesMissed;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("yellowCards")) {
          if (player4.yellowCards == player1.yellowCards && player1unveiled.yellowCards != player4.yellowCards) {
            player1unveiled.yellowCards = player4.yellowCards;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player4.yellowCards == player2.yellowCards && player2unveiled.yellowCards != player4.yellowCards) {
            player2unveiled.yellowCards = player4.yellowCards;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player4.yellowCards == player3.yellowCards && player4unveiled.yellowCards != player3.yellowCards) {
            player4unveiled.yellowCards = player4.yellowCards;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player4.yellowCards == player5.yellowCards && player5unveiled.yellowCards != player4.yellowCards) {
            player5unveiled.yellowCards = player4.yellowCards;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("redCards")) {
          if (player4.redCards == player1.redCards && player1unveiled.redCards != player4.redCards) {
            player1unveiled.redCards = player4.redCards;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player4.redCards == player2.redCards && player2unveiled.redCards != player4.redCards) {
            player2unveiled.redCards = player4.redCards;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player4.redCards == player3.redCards && player4unveiled.redCards != player3.redCards) {
            player4unveiled.redCards = player4.redCards;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player4.redCards == player5.redCards && player5unveiled.redCards != player4.redCards) {
            player5unveiled.redCards = player4.redCards;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("starts")) {
          if (player4.starts == player1.starts && player1unveiled.starts != player4.starts) {
            player1unveiled.starts = player4.starts;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player4.starts == player2.starts && player2unveiled.starts != player4.starts) {
            player2unveiled.starts = player4.starts;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player4.starts == player3.starts && player4unveiled.starts != player3.starts) {
            player4unveiled.starts = player4.starts;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player4.starts == player5.starts && player5unveiled.starts != player4.starts) {
            player5unveiled.starts = player4.starts;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("pointsPerGame")) {
          if (player4.pointsPerGame == player1.pointsPerGame &&
              player1unveiled.pointsPerGame != player4.pointsPerGame) {
            player1unveiled.pointsPerGame = player4.pointsPerGame;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player4.pointsPerGame == player2.pointsPerGame &&
              player2unveiled.pointsPerGame != player4.pointsPerGame) {
            player2unveiled.pointsPerGame = player4.pointsPerGame;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player4.pointsPerGame == player3.pointsPerGame &&
              player4unveiled.pointsPerGame != player3.pointsPerGame) {
            player4unveiled.pointsPerGame = player4.pointsPerGame;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player4.pointsPerGame == player5.pointsPerGame &&
              player5unveiled.pointsPerGame != player4.pointsPerGame) {
            player5unveiled.pointsPerGame = player4.pointsPerGame;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("goalsScored")) {
          if (player4.goalsScored == player1.goalsScored && player1unveiled.goalsScored != player4.goalsScored) {
            player1unveiled.goalsScored = player4.goalsScored;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player4.goalsScored == player2.goalsScored && player2unveiled.goalsScored != player4.goalsScored) {
            player2unveiled.goalsScored = player4.goalsScored;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player4.goalsScored == player3.goalsScored && player4unveiled.goalsScored != player3.goalsScored) {
            player4unveiled.goalsScored = player4.goalsScored;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
          if (player4.goalsScored == player5.goalsScored && player5unveiled.goalsScored != player4.goalsScored) {
            player5unveiled.goalsScored = player4.goalsScored;
            _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
          }
        }
      } else if (guess == "${player5.firstName} ${player5.secondName}") {
        isGuessRight = true;
        isAnyMatchFound = true;
        player5unveiled = player5;
        player5unveiled.isUnveiled = true;
        _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
        snackBarHelper(context, message: "Player found: $guess");
        animateUnveiledPuzzleCard(context, 5);

        // handle matching team
        if (player5.team == player1.team && player1unveiled.team != player5.team) {
          isAnyMatchFound = true;
          player1unveiled.team = player5.team;
          _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
        }

        if (player5.team == player2.team && player2unveiled.team != player5.team) {
          isAnyMatchFound = true;
          player2unveiled.team = player5.team;
          _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
        }

        if (player5.team == player3.team && player3unveiled.team != player5.team) {
          isAnyMatchFound = true;
          player3unveiled.team = player5.team;
          _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
        }

        if (player5.team == player4.team && player4unveiled.team != player5.team) {
          isAnyMatchFound = true;
          player4unveiled.team = player5.team;
          _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
        }

        // other matching traits
        if (selectedAttributes.contains("goalsScored")) {
          if (player5.goalsScored == player1.goalsScored && player1unveiled.goalsScored != player5.goalsScored) {
            player1unveiled.goalsScored = player5.goalsScored;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player5.goalsScored == player2.goalsScored && player2unveiled.goalsScored != player5.goalsScored) {
            player2unveiled.goalsScored = player5.goalsScored;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player5.goalsScored == player3.goalsScored && player3unveiled.goalsScored != player5.goalsScored) {
            player3unveiled.goalsScored = player5.goalsScored;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player5.goalsScored == player4.goalsScored && player4unveiled.goalsScored != player5.goalsScored) {
            player4unveiled.goalsScored = player5.goalsScored;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("penaltiesMissed")) {
          if (player5.penaltiesMissed == player1.penaltiesMissed &&
              player1unveiled.penaltiesMissed != player5.penaltiesMissed) {
            player1unveiled.penaltiesMissed = player5.penaltiesMissed;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player5.penaltiesMissed == player2.penaltiesMissed &&
              player2unveiled.penaltiesMissed != player5.penaltiesMissed) {
            player2unveiled.penaltiesMissed = player5.penaltiesMissed;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player5.penaltiesMissed == player3.penaltiesMissed &&
              player3unveiled.penaltiesMissed != player5.penaltiesMissed) {
            player3unveiled.penaltiesMissed = player5.penaltiesMissed;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player5.penaltiesMissed == player4.penaltiesMissed &&
              player4unveiled.penaltiesMissed != player5.penaltiesMissed) {
            player4unveiled.penaltiesMissed = player5.penaltiesMissed;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("yellowCards")) {
          if (player5.yellowCards == player1.yellowCards && player1unveiled.yellowCards != player5.yellowCards) {
            player1unveiled.yellowCards = player5.yellowCards;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player5.yellowCards == player2.yellowCards && player2unveiled.yellowCards != player5.yellowCards) {
            player2unveiled.yellowCards = player5.yellowCards;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player5.yellowCards == player3.yellowCards && player3unveiled.yellowCards != player5.yellowCards) {
            player3unveiled.yellowCards = player5.yellowCards;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player5.yellowCards == player4.yellowCards && player4unveiled.yellowCards != player5.yellowCards) {
            player4unveiled.yellowCards = player5.yellowCards;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("redCards")) {
          if (player5.redCards == player1.redCards && player1unveiled.redCards != player5.redCards) {
            player1unveiled.redCards = player5.redCards;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player5.redCards == player2.redCards && player2unveiled.redCards != player5.redCards) {
            player2unveiled.redCards = player5.redCards;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player5.redCards == player3.redCards && player3unveiled.redCards != player5.redCards) {
            player3unveiled.redCards = player5.redCards;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player5.redCards == player4.redCards && player4unveiled.redCards != player5.redCards) {
            player4unveiled.redCards = player5.redCards;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("starts")) {
          if (player5.starts == player1.starts && player1unveiled.starts != player5.starts) {
            player1unveiled.starts = player5.starts;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player5.starts == player2.starts && player2unveiled.starts != player5.starts) {
            player2unveiled.starts = player5.starts;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player5.starts == player3.starts && player3unveiled.starts != player5.starts) {
            player3unveiled.starts = player5.starts;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player5.starts == player4.starts && player4unveiled.starts != player5.starts) {
            player4unveiled.starts = player5.starts;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("totalPoints")) {
          if (player5.totalPoints == player1.totalPoints && player1unveiled.totalPoints != player5.totalPoints) {
            player1unveiled.totalPoints = player5.totalPoints;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player5.totalPoints == player2.totalPoints && player2unveiled.totalPoints != player5.totalPoints) {
            player2unveiled.totalPoints = player5.totalPoints;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player5.totalPoints == player3.totalPoints && player3unveiled.totalPoints != player5.totalPoints) {
            player3unveiled.totalPoints = player5.totalPoints;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player5.totalPoints == player4.totalPoints && player4unveiled.totalPoints != player5.totalPoints) {
            player4unveiled.totalPoints = player5.totalPoints;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("bonus")) {
          if (player5.bonus == player1.bonus && player1unveiled.bonus != player5.bonus) {
            player1unveiled.bonus = player5.bonus;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player5.bonus == player2.bonus && player2unveiled.bonus != player5.bonus) {
            player2unveiled.bonus = player5.bonus;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player5.bonus == player3.bonus && player3unveiled.bonus != player5.bonus) {
            player3unveiled.bonus = player5.bonus;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player5.bonus == player4.bonus && player4unveiled.bonus != player5.bonus) {
            player4unveiled.bonus = player5.bonus;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("assists")) {
          if (player5.assists == player1.assists && player1unveiled.assists != player5.assists) {
            player1unveiled.assists = player5.assists;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player5.assists == player2.assists && player2unveiled.assists != player5.assists) {
            player2unveiled.assists = player5.assists;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player5.assists == player3.assists && player3unveiled.assists != player5.assists) {
            player3unveiled.assists = player5.assists;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player5.assists == player4.assists && player4unveiled.assists != player5.assists) {
            player4unveiled.assists = player5.assists;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("cleanSheets")) {
          if (player5.cleanSheets == player1.cleanSheets && player1unveiled.cleanSheets != player5.cleanSheets) {
            player1unveiled.cleanSheets = player5.cleanSheets;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player5.cleanSheets == player2.cleanSheets && player2unveiled.cleanSheets != player5.cleanSheets) {
            player2unveiled.cleanSheets = player5.cleanSheets;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player5.cleanSheets == player3.cleanSheets && player3unveiled.cleanSheets != player5.cleanSheets) {
            player3unveiled.cleanSheets = player5.cleanSheets;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player5.cleanSheets == player4.cleanSheets && player4unveiled.cleanSheets != player5.cleanSheets) {
            player4unveiled.cleanSheets = player5.cleanSheets;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("goalsConceded")) {
          if (player5.goalsConceded == player1.goalsConceded &&
              player1unveiled.goalsConceded != player5.goalsConceded) {
            player1unveiled.goalsConceded = player5.goalsConceded;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player5.goalsConceded == player2.goalsConceded &&
              player2unveiled.goalsConceded != player5.goalsConceded) {
            player2unveiled.goalsConceded = player5.goalsConceded;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player5.goalsConceded == player3.goalsConceded &&
              player3unveiled.goalsConceded != player5.goalsConceded) {
            player3unveiled.goalsConceded = player5.goalsConceded;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player5.goalsConceded == player4.goalsConceded &&
              player4unveiled.goalsConceded != player5.goalsConceded) {
            player4unveiled.goalsConceded = player5.goalsConceded;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("ownGoals")) {
          if (player5.ownGoals == player1.ownGoals && player1unveiled.ownGoals != player5.ownGoals) {
            player1unveiled.ownGoals = player5.ownGoals;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player5.ownGoals == player2.ownGoals && player2unveiled.ownGoals != player5.ownGoals) {
            player2unveiled.ownGoals = player5.ownGoals;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player5.ownGoals == player3.ownGoals && player3unveiled.ownGoals != player5.ownGoals) {
            player3unveiled.ownGoals = player5.ownGoals;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player5.ownGoals == player4.ownGoals && player4unveiled.ownGoals != player5.ownGoals) {
            player4unveiled.ownGoals = player5.ownGoals;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
        }

        if (selectedAttributes.contains("pointsPerGame")) {
          if (player5.pointsPerGame == player1.pointsPerGame &&
              player1unveiled.pointsPerGame != player5.pointsPerGame) {
            player1unveiled.pointsPerGame = player5.pointsPerGame;
            _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
          }
          if (player5.pointsPerGame == player2.pointsPerGame &&
              player2unveiled.pointsPerGame != player5.pointsPerGame) {
            player2unveiled.pointsPerGame = player5.pointsPerGame;
            _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
          }
          if (player5.pointsPerGame == player3.pointsPerGame &&
              player3unveiled.pointsPerGame != player5.pointsPerGame) {
            player3unveiled.pointsPerGame = player5.pointsPerGame;
            _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
          }
          if (player5.pointsPerGame == player4.pointsPerGame &&
              player4unveiled.pointsPerGame != player5.pointsPerGame) {
            player4unveiled.pointsPerGame = player5.pointsPerGame;
            _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
          }
        }
      }

      // ** deplete lives if guess is wrong && find players with matching traits ** //
      // ** handle other achievement and score related things ** //
      if (!isGuessRight) {
        // set streak to zero
        _puzzle!.streak = 0;
        // deplete lives
        puzzle!.lives = puzzle!.lives! - 1;

        // find the index of the player whose firstName and lastName equals guess
        for (Player player in _players) {
          if (guess.trim() == "${player.firstName} ${player.secondName}".trim()) {
            // handle matching team
            if (player.team == player1.team && player1unveiled.team != player.team) {
              isAnyMatchFound = true;
              player1unveiled.team = player.team;
              _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
            }
            if (player.team == player2.team && player2unveiled.team != player.team) {
              isAnyMatchFound = true;
              player2unveiled.team = player.team;
              _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
            }
            if (player.team == player3.team && player3unveiled.team != player.team) {
              isAnyMatchFound = true;
              player3unveiled.team = player.team;
              _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
            }
            if (player.team == player4.team && player4unveiled.team != player.team) {
              isAnyMatchFound = true;
              player4unveiled.team = player.team;
              _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
            }
            if (player.team == player5.team && player5unveiled.team != player.team) {
              isAnyMatchFound = true;
              player5unveiled.team = player.team;
              _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
            }

            if (selectedAttributes.contains("totalPoints")) {
              if (player.totalPoints == player1.totalPoints && player1unveiled.totalPoints != player.totalPoints) {
                isAnyMatchFound = true;
                player1unveiled.totalPoints = player.totalPoints;
                _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
              }
              if (player.totalPoints == player2.totalPoints && player2unveiled.totalPoints != player.totalPoints) {
                isAnyMatchFound = true;
                player2unveiled.totalPoints = player.totalPoints;
                _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
              }
              if (player.totalPoints == player3.totalPoints && player3unveiled.totalPoints != player.totalPoints) {
                isAnyMatchFound = true;
                player3unveiled.totalPoints = player.totalPoints;
                _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
              }
              if (player.totalPoints == player4.totalPoints && player4unveiled.totalPoints != player.totalPoints) {
                isAnyMatchFound = true;
                player4unveiled.totalPoints = player.totalPoints;
                _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
              }
              if (player.totalPoints == player5.totalPoints && player5unveiled.totalPoints != player.totalPoints) {
                isAnyMatchFound = true;
                player5unveiled.totalPoints = player.totalPoints;
                _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
              }
            }

            if (selectedAttributes.contains("bonus")) {
              if (player.bonus == player1.bonus && player1unveiled.bonus != player.bonus) {
                isAnyMatchFound = true;
                player1unveiled.bonus = player.bonus;
                _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
              }
              if (player.bonus == player2.bonus && player2unveiled.bonus != player.bonus) {
                isAnyMatchFound = true;
                player2unveiled.bonus = player.bonus;
                _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
              }
              if (player.bonus == player3.bonus && player3unveiled.bonus != player.bonus) {
                isAnyMatchFound = true;
                player3unveiled.bonus = player.bonus;
                _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
              }
              if (player.bonus == player4.bonus && player4unveiled.bonus != player.bonus) {
                isAnyMatchFound = true;
                player4unveiled.bonus = player.bonus;
                _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
              }
              if (player.bonus == player5.bonus && player5unveiled.bonus != player.bonus) {
                isAnyMatchFound = true;
                player5unveiled.bonus = player.bonus;
                _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
              }
            }

            if (selectedAttributes.contains("goalsScored")) {
              if (player.goalsScored == player1.goalsScored && player1unveiled.goalsScored != player.goalsScored) {
                isAnyMatchFound = true;
                player1unveiled.goalsScored = player.goalsScored;
                _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
              }
              if (player.goalsScored == player2.goalsScored && player2unveiled.goalsScored != player.goalsScored) {
                isAnyMatchFound = true;
                player2unveiled.goalsScored = player.goalsScored;
                _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
              }
              if (player.goalsScored == player3.goalsScored && player3unveiled.goalsScored != player.goalsScored) {
                isAnyMatchFound = true;
                player3unveiled.goalsScored = player.goalsScored;
                _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
              }
              if (player.goalsScored == player4.goalsScored && player4unveiled.goalsScored != player.goalsScored) {
                isAnyMatchFound = true;
                player4unveiled.goalsScored = player.goalsScored;
                _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
              }
              if (player.goalsScored == player5.goalsScored && player5unveiled.goalsScored != player.goalsScored) {
                isAnyMatchFound = true;
                player5unveiled.goalsScored = player.goalsScored;
                _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
              }
            }

            if (selectedAttributes.contains("assists")) {
              if (player.assists == player1.assists && player1unveiled.assists != player.assists) {
                isAnyMatchFound = true;
                player1unveiled.assists = player.assists;
                _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
              }
              if (player.assists == player2.assists && player2unveiled.assists != player.assists) {
                isAnyMatchFound = true;
                player2unveiled.assists = player.assists;
                _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
              }
              if (player.assists == player3.assists && player3unveiled.assists != player.assists) {
                isAnyMatchFound = true;
                player3unveiled.assists = player.assists;
                _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
              }
              if (player.assists == player4.assists && player4unveiled.assists != player.assists) {
                isAnyMatchFound = true;
                player4unveiled.assists = player.assists;
                _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
              }
              if (player.assists == player5.assists && player5unveiled.assists != player.assists) {
                isAnyMatchFound = true;
                player5unveiled.assists = player.assists;
                _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
              }
            }

            if (selectedAttributes.contains("cleanSheets")) {
              if (player.cleanSheets == player1.cleanSheets && player1unveiled.cleanSheets != player.cleanSheets) {
                isAnyMatchFound = true;
                player1unveiled.cleanSheets = player.cleanSheets;
                _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
              }
              if (player.cleanSheets == player2.cleanSheets && player2unveiled.cleanSheets != player.cleanSheets) {
                isAnyMatchFound = true;
                player2unveiled.cleanSheets = player.cleanSheets;
                _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
              }
              if (player.cleanSheets == player3.cleanSheets && player3unveiled.cleanSheets != player.cleanSheets) {
                isAnyMatchFound = true;
                player3unveiled.cleanSheets = player.cleanSheets;
                _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
              }
              if (player.cleanSheets == player4.cleanSheets && player4unveiled.cleanSheets != player.cleanSheets) {
                isAnyMatchFound = true;
                player4unveiled.cleanSheets = player.cleanSheets;
                _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
              }
              if (player.cleanSheets == player5.cleanSheets && player5unveiled.cleanSheets != player.cleanSheets) {
                isAnyMatchFound = true;
                player5unveiled.cleanSheets = player.cleanSheets;
                _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
              }
            }

            if (selectedAttributes.contains("goalsConceded")) {
              if (player.goalsConceded == player1.goalsConceded &&
                  player1unveiled.goalsConceded != player.goalsConceded) {
                isAnyMatchFound = true;
                player1unveiled.goalsConceded = player.goalsConceded;
                _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
              }
              if (player.goalsConceded == player2.goalsConceded &&
                  player2unveiled.goalsConceded != player.goalsConceded) {
                isAnyMatchFound = true;
                player2unveiled.goalsConceded = player.goalsConceded;
                _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
              }
              if (player.goalsConceded == player3.goalsConceded &&
                  player3unveiled.goalsConceded != player.goalsConceded) {
                isAnyMatchFound = true;
                player3unveiled.goalsConceded = player.goalsConceded;
                _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
              }
              if (player.goalsConceded == player4.goalsConceded &&
                  player4unveiled.goalsConceded != player.goalsConceded) {
                isAnyMatchFound = true;
                player4unveiled.goalsConceded = player.goalsConceded;
                _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
              }
              if (player.goalsConceded == player5.goalsConceded &&
                  player5unveiled.goalsConceded != player.goalsConceded) {
                isAnyMatchFound = true;
                player5unveiled.goalsConceded = player.goalsConceded;
                _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
              }
            }

            if (selectedAttributes.contains("ownGoals")) {
              if (player.ownGoals == player1.ownGoals && player1unveiled.ownGoals != player.ownGoals) {
                isAnyMatchFound = true;
                player1unveiled.ownGoals = player.ownGoals;
                _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
              }
              if (player.ownGoals == player2.ownGoals && player2unveiled.ownGoals != player.ownGoals) {
                isAnyMatchFound = true;
                player2unveiled.ownGoals = player.ownGoals;
                _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
              }
              if (player.ownGoals == player3.ownGoals && player3unveiled.ownGoals != player.ownGoals) {
                isAnyMatchFound = true;
                player3unveiled.ownGoals = player.ownGoals;
                _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
              }
              if (player.ownGoals == player4.ownGoals && player4unveiled.ownGoals != player.ownGoals) {
                isAnyMatchFound = true;
                player4unveiled.ownGoals = player.ownGoals;
                _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
              }
              if (player.ownGoals == player5.ownGoals && player5unveiled.ownGoals != player.ownGoals) {
                isAnyMatchFound = true;
                player5unveiled.ownGoals = player.ownGoals;
                _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
              }
            }

            if (selectedAttributes.contains("penaltiesMissed")) {
              if (player.penaltiesMissed == player1.penaltiesMissed &&
                  player1unveiled.penaltiesMissed != player.penaltiesMissed) {
                isAnyMatchFound = true;
                player1unveiled.penaltiesMissed = player.penaltiesMissed;
                _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
              }
              if (player.penaltiesMissed == player2.penaltiesMissed &&
                  player2unveiled.penaltiesMissed != player.penaltiesMissed) {
                isAnyMatchFound = true;
                player2unveiled.penaltiesMissed = player.penaltiesMissed;
                _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
              }
              if (player.penaltiesMissed == player3.penaltiesMissed &&
                  player3unveiled.penaltiesMissed != player.penaltiesMissed) {
                isAnyMatchFound = true;
                player3unveiled.penaltiesMissed = player.penaltiesMissed;
                _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
              }
              if (player.penaltiesMissed == player4.penaltiesMissed &&
                  player4unveiled.penaltiesMissed != player.penaltiesMissed) {
                isAnyMatchFound = true;
                player4unveiled.penaltiesMissed = player.penaltiesMissed;
                _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
              }
              if (player.penaltiesMissed == player5.penaltiesMissed &&
                  player5unveiled.penaltiesMissed != player.penaltiesMissed) {
                isAnyMatchFound = true;
                player5unveiled.penaltiesMissed = player.penaltiesMissed;
                _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
              }
            }

            if (selectedAttributes.contains("yellowCards")) {
              if (player.yellowCards == player1.yellowCards && player1unveiled.yellowCards != player.yellowCards) {
                isAnyMatchFound = true;
                player1unveiled.yellowCards = player.yellowCards;
                _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
              }
              if (player.yellowCards == player2.yellowCards && player2unveiled.yellowCards != player.yellowCards) {
                isAnyMatchFound = true;
                player2unveiled.yellowCards = player.yellowCards;
                _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
              }
              if (player.yellowCards == player3.yellowCards && player3unveiled.yellowCards != player.yellowCards) {
                isAnyMatchFound = true;
                player3unveiled.yellowCards = player.yellowCards;
                _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
              }
              if (player.yellowCards == player4.yellowCards && player4unveiled.yellowCards != player.yellowCards) {
                isAnyMatchFound = true;
                player4unveiled.yellowCards = player.yellowCards;
                _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
              }
              if (player.yellowCards == player5.yellowCards && player5unveiled.yellowCards != player.yellowCards) {
                isAnyMatchFound = true;
                player5unveiled.yellowCards = player.yellowCards;
                _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
              }
            }

            if (selectedAttributes.contains("redCards")) {
              if (player.redCards == player1.redCards && player1unveiled.redCards != player.redCards) {
                isAnyMatchFound = true;
                player1unveiled.redCards = player.redCards;
                _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
              }
              if (player.redCards == player2.redCards && player2unveiled.redCards != player.redCards) {
                isAnyMatchFound = true;
                player2unveiled.redCards = player.redCards;
                _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
              }
              if (player.redCards == player3.redCards && player3unveiled.redCards != player.redCards) {
                isAnyMatchFound = true;
                player3unveiled.redCards = player.redCards;
                _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
              }
              if (player.redCards == player4.redCards && player4unveiled.redCards != player.redCards) {
                isAnyMatchFound = true;
                player4unveiled.redCards = player.redCards;
                _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
              }
              if (player.redCards == player5.redCards && player5unveiled.redCards != player.redCards) {
                isAnyMatchFound = true;
                player5unveiled.redCards = player.redCards;
                _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
              }
            }

            if (selectedAttributes.contains("starts")) {
              if (player.starts == player1.starts && player1unveiled.starts != player.starts) {
                isAnyMatchFound = true;
                player1unveiled.starts = player.starts;
                _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
              }
              if (player.starts == player2.starts && player2unveiled.starts != player.starts) {
                isAnyMatchFound = true;
                player2unveiled.starts = player.starts;
                _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
              }
              if (player.starts == player3.starts && player3unveiled.starts != player.starts) {
                isAnyMatchFound = true;
                player3unveiled.starts = player.starts;
                _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
              }
              if (player.starts == player4.starts && player4unveiled.starts != player.starts) {
                isAnyMatchFound = true;
                player4unveiled.starts = player.starts;
                _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
              }
              if (player.starts == player5.starts && player5unveiled.starts != player.starts) {
                isAnyMatchFound = true;
                player5unveiled.starts = player.starts;
                _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
              }
            }

            if (selectedAttributes.contains("pointsPerGame")) {
              if (player.pointsPerGame == player1.pointsPerGame &&
                  player1unveiled.pointsPerGame != player.pointsPerGame) {
                isAnyMatchFound = true;
                player1unveiled.pointsPerGame = player.pointsPerGame;
                _puzzle!.player1unveiled = jsonEncode(player1unveiled.toJson());
              }
              if (player.pointsPerGame == player2.pointsPerGame &&
                  player2unveiled.pointsPerGame != player.pointsPerGame) {
                isAnyMatchFound = true;
                player2unveiled.pointsPerGame = player.pointsPerGame;
                _puzzle!.player2unveiled = jsonEncode(player2unveiled.toJson());
              }
              if (player.pointsPerGame == player3.pointsPerGame &&
                  player3unveiled.pointsPerGame != player.pointsPerGame) {
                isAnyMatchFound = true;
                player3unveiled.pointsPerGame = player.pointsPerGame;
                _puzzle!.player3unveiled = jsonEncode(player3unveiled.toJson());
              }
              if (player.pointsPerGame == player4.pointsPerGame &&
                  player4unveiled.pointsPerGame != player.pointsPerGame) {
                isAnyMatchFound = true;
                player4unveiled.pointsPerGame = player.pointsPerGame;
                _puzzle!.player4unveiled = jsonEncode(player4unveiled.toJson());
              }
              if (player.pointsPerGame == player5.pointsPerGame &&
                  player5unveiled.pointsPerGame != player.pointsPerGame) {
                isAnyMatchFound = true;
                player5unveiled.pointsPerGame = player.pointsPerGame;
                _puzzle!.player5unveiled = jsonEncode(player5unveiled.toJson());
              }
            }

            break;
          }
        }
      } else {
        // increase player found
        context.read<ProfileProvider>().increasePlayersFoundCount();

        // increase score
        _puzzle!.score = _puzzle!.score! + 10;

        // increment streak
        _puzzle!.streak = _puzzle!.streak! + 1;

        // ** handle first correct guess ** //
        // check difficulty level from user profile
        Profile profile = Profile();
        if (context.mounted) profile = context.read<ProfileProvider>().profile!;
        int difficulty = profile.difficulty!;

        // lives (based on difficulty level)
        int originalLives = difficulty == 1
            ? 20
            : difficulty == 2
                ? 15
                : 10;
        if (_puzzle!.lives == originalLives && _puzzle!.isFirstGuessMade == false) {
          // increase score
          _puzzle!.score = _puzzle!.score! + 10;
          snackBarHelper(context, message: "Correct First Guess: +10");
          _puzzle!.isFirstGuessMade = true;
          // increase in profile
          context.read<ProfileProvider>().increaseCorrectFirstGuessCount();
        }

        // ** handle streak ** //
        // for points increment
        if (_puzzle!.streak! > 1) {
          _puzzle!.score = _puzzle!.score! + 5;
          snackBarHelper(context, message: "Streak x${_puzzle!.streak}: +5 points");
        }

        // for profile
        if (_puzzle!.streak! > profile.longestWinStreak!) {
          context.read<ProfileProvider>().increaseLongestWinStreakCount(_puzzle!.streak!);
        }
      }

      // ** show a snackbar if no match is found ** //
      if (!isAnyMatchFound && context.mounted) {
        context.read<SoundsProvider>().playError();
        snackBarHelper(context,
            message: "No match found. Remaining ${_puzzle!.lives} lives", type: AnimatedSnackBarType.error);
      }

      if (isAnyMatchFound && !isGuessRight && context.mounted) {
        snackBarHelper(context,
            message: "Wrong guess, but matching traits found Remaining ${_puzzle!.lives} lives",
            type: AnimatedSnackBarType.info);
      }

      // ** check if all players are unveiled, if so, puzzle is solved ** //
      bool isAllUnveiled = player1unveiled.isUnveiled == true &&
          player2unveiled.isUnveiled == true &&
          player3unveiled.isUnveiled == true &&
          player4unveiled.isUnveiled == true &&
          player5unveiled.isUnveiled == true;
      if (isAllUnveiled && context.mounted) {
        setGameComplete(context, shouldNotifyListeners: true);
      }

      // ** remove player from suggestions ** //
      if (context.mounted) {
        context.read<KeyboardProvider>().removePlayerName(guess.trim());
        _players.removeWhere((player) => "${player.firstName} ${player.secondName}".trim() == guess.trim());
        _puzzle!.allPlayersEncodedJSONstring = jsonEncode(_players.map((e) => e.toJson()).toList());
      }

      // ** save game in session ** //
      SingleModePuzzle temp = _puzzle!;
      _puzzle = null;
      _puzzle = temp;

      _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

      await secStorage.write(key: SharedPrefsConsts.gameInSession, value: jsonEncode(_puzzle!.toJson()));

      notifyListeners();
    }
  }

  ({String name, String shirtAsset}) getTeam(int teamNo, bool isGk) {
    switch (teamNo) {
      case 1:
        return (name: "Arsenal", shirtAsset: isGk ? "assets/shirts/shirt_1_1.png" : "assets/shirts/shirt_1.png");
      case 2:
        return (name: "A. Villa", shirtAsset: isGk ? "assets/shirts/shirt_2_1.png" : "assets/shirts/shirt_2.png");
      case 3:
        return (name: "Bournemouth", shirtAsset: isGk ? "assets/shirts/shirt_3_1.png" : "assets/shirts/shirt_3.png");
      case 4:
        return (name: "Brentford", shirtAsset: isGk ? "assets/shirts/shirt_4_1.png" : "assets/shirts/shirt_4.png");
      case 5:
        return (name: "Brighton", shirtAsset: isGk ? "assets/shirts/shirt_5_1.png" : "assets/shirts/shirt_5.png");
      case 6:
        return (name: "Chelsea", shirtAsset: isGk ? "assets/shirts/shirt_6_1.png" : "assets/shirts/shirt_6.png");
      case 7:
        return (name: "Crystal Palace", shirtAsset: isGk ? "assets/shirts/shirt_7_1.png" : "assets/shirts/shirt_7.png");
      case 8:
        return (name: "Everton", shirtAsset: isGk ? "assets/shirts/shirt_8_1.png" : "assets/shirts/shirt_8.png");
      case 9:
        return (name: "Fulham", shirtAsset: isGk ? "assets/shirts/shirt_9_1.png" : "assets/shirts/shirt_9.png");
      case 10:
        return (name: "Leicester", shirtAsset: isGk ? "assets/shirts/shirt_10_1.png" : "assets/shirts/shirt_10.png");
      case 11:
        return (name: "Leeds", shirtAsset: isGk ? "assets/shirts/shirt_11_1.png" : "assets/shirts/shirt_11.png");
      case 12:
        return (name: "Liverpool", shirtAsset: isGk ? "assets/shirts/shirt_12_1.png" : "assets/shirts/shirt_12.png");
      case 13:
        return (name: "Man City", shirtAsset: isGk ? "assets/shirts/shirt_13_1.png" : "assets/shirts/shirt_13.png");
      case 14:
        return (name: "Man Utd", shirtAsset: isGk ? "assets/shirts/shirt_14_1.png" : "assets/shirts/shirt_14.png");
      case 15:
        return (name: "Newcastle", shirtAsset: isGk ? "assets/shirts/shirt_15_1.png" : "assets/shirts/shirt_15.png");
      case 16:
        return (name: "Nott Forest", shirtAsset: isGk ? "assets/shirts/shirt_16_1.png" : "assets/shirts/shirt_16.png");
      case 17:
        return (name: "Southampton", shirtAsset: isGk ? "assets/shirts/shirt_17_1.png" : "assets/shirts/shirt_17.png");
      case 18:
        return (name: "Tottenham", shirtAsset: isGk ? "assets/shirts/shirt_18_1.png" : "assets/shirts/shirt_18.png");
      case 19:
        return (name: "West Ham", shirtAsset: isGk ? "assets/shirts/shirt_19_1.png" : "assets/shirts/shirt_19.png");
      case 20:
        return (name: "Wolves", shirtAsset: isGk ? "assets/shirts/shirt_20_1.png" : "assets/shirts/shirt_20.png");
      default:
        return (name: "Team", shirtAsset: "assets/shirts/shirt_0.png");
    }
  }

  int getHintBonus() {
    return _puzzle!.hints! * 10;
  }

  int getLifeBonus(BuildContext context) {
    int multiplier = 2;
    // check difficulty
    Profile profile = Profile();
    if (context.mounted) profile = context.read<ProfileProvider>().profile!;
    int difficulty = profile.difficulty!;

    switch (difficulty) {
      case 1:
        multiplier = 2;
        break;
      case 2:
        multiplier = 4;
        break;
      case 3:
        multiplier = 8;
        break;
      default:
    }

    return _puzzle!.lives! * multiplier;
  }
}
