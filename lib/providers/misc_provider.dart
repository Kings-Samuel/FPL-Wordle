import 'package:flutter/material.dart';

class MiscProvider extends ChangeNotifier {
  Duration _durationUntilNextGame = Duration.zero;

  Duration get durationUntilNextGame => _durationUntilNextGame;

  MiscProvider() {
    _setDurationUntilNextGame();
  }

  void _setDurationUntilNextGame() {
    // duration until next game at 17:00 UTC
    final DateTime now = DateTime.now().toUtc();
    final DateTime nextGame = DateTime(now.year, now.month, now.day, 17, 0, 0).toUtc();
    _durationUntilNextGame = nextGame.difference(now);
  }
}