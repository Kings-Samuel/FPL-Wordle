import 'dart:convert';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/consts/consts.dart';
import 'package:fplwordle/helpers/utils/init_appwrite.dart';
import 'package:fplwordle/helpers/utils/sec_storage.dart';
import 'package:fplwordle/helpers/widgets/snack_bar_helper.dart';
import 'package:fplwordle/models/single_mode_puzzle.dart';
import 'package:fplwordle/providers/profile_provider.dart';

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
    String? lastGameTime = await secStorage.read(key: 'lastGameTime');

    if (lastGameTime == null) {
      return false;
    } else {
      final now = DateTime.now().toUtc();
      final lastGameTimeEpoch = int.parse(lastGameTime);
      final nowEpoch = now.millisecondsSinceEpoch;
      final five5PMtoday = DateTime(now.year, now.month, now.day, 17, 0, 0).toUtc();
      final five5PMtodayEpoch = five5PMtoday.millisecondsSinceEpoch;
      final five5PMyesterday = five5PMtoday.subtract(const Duration(days: 1));
      final five5PMyesterdayEpoch = five5PMyesterday.millisecondsSinceEpoch;

      if (nowEpoch < five5PMtodayEpoch) {
        if (lastGameTimeEpoch >= five5PMyesterdayEpoch) {
          return true;
        } else {
          await profileProvider.increaseForfeitCount();
          await secStorage.delete(key: "lastGameTime");
          await secStorage.delete(key: "gameInSession");
          return false;
        }
      } else {
        await profileProvider.increaseForfeitCount();
        await secStorage.delete(key: "lastGameTime");
        await secStorage.delete(key: "gameInSession");
        return false;
      }
    }
  }

  Future<void> loadNewGame(BuildContext context) async {
    try {
      DateTime now = DateTime.now().toUtc();
      final documentId = now.millisecondsSinceEpoch.toString();

      final res = await database.getDocument(
          databaseId: Consts.db, collectionId: "6456280fce7bda9ca877", documentId: documentId);

      _puzzle = SingleModePuzzle.fromJson(res.data);

      await secStorage.write(key: "gameInSession", value: jsonEncode(_puzzle!.toJson()));
      now = DateTime.now().toUtc();
      final lastGameTime = now.millisecondsSinceEpoch.toString();
      await secStorage.write(key: "lastGameTime", value: lastGameTime);

      notifyListeners();
    } on AppwriteException catch (e) {
      _error = e.message!;
      debugPrint(_error);
      snackBarHelper(context, message: _error, type: AnimatedSnackBarType.error);
    }
  }

  Future<void> loadGameInSession() async {
    await secStorage.read(key: "gameInSession").then((value) {
      if (value != null) {
        _puzzle = SingleModePuzzle.fromJson(jsonDecode(value));
        notifyListeners();
      }
    });
  }

}
