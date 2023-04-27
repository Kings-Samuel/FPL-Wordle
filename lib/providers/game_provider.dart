import 'package:flutter/material.dart';

class GameProvider extends ChangeNotifier {
  Duration _durationUntilNextGame = Duration.zero;

  Duration get durationUntilNextGame => _durationUntilNextGame;

 GameProvider() {
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
}
