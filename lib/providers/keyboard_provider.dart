import 'package:flutter/material.dart';
import '../models/player.dart';

class KeyboardProvider extends ChangeNotifier {
  String _input = '';
  String _typed = '';
  bool _isBackSpaceClicked = false;
  bool _isHintClicked = false;
  final List<String> _playerNames = [];
  List<String> _suggestions = [];

  String get input => _input;
  String get typed => _typed;
  bool get isBackSpaceClicked => _isBackSpaceClicked;
  bool get isHintClicked => _isHintClicked;
  List<String> get suggestions => _suggestions;

  void addInput(String input) {
    _input += input;
    notifyListeners();
  }

  void setTyped(String letter) async {
    _typed = letter;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 150));
    _typed = '';
    setSuggestions(_input);
    notifyListeners();
  }

  void backSpace() {
    if (_input.isNotEmpty) {
      _input = _input.substring(0, _input.length - 1);
      _isBackSpaceClicked = true;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 150), () {
        _isBackSpaceClicked = false;
        setSuggestions(_input);
        notifyListeners();
      });
    }
  }

  Future<void> hintButtonFeedback() async {
    _isHintClicked = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 150), () {
      _isHintClicked = false;
      notifyListeners();
    });
  }

  void clearInput() {
    _input = '';
    _suggestions = [];
    notifyListeners();
  }

  void setSuggestions(String input) {
    _suggestions = _playerNames.where((element) => element.toLowerCase().contains(input.toLowerCase())).toList();
    // sort suggestions alphabetically
    _suggestions.sort((a, b) => a.compareTo(b));
    notifyListeners();
  }

  void useSuggestion(String suggestion) async {
    _input = suggestion.toUpperCase();
    _suggestions = [];
    notifyListeners();
    Future.delayed(const Duration(seconds: 1), () {
      _input = '';
      notifyListeners();
    });
  }

  // get all player names from player_names.json in assets
  void getPlayerNames(List<Player> players) async {
    // clear list before adding new names
    _playerNames.clear();

    for (Player player in players) {
      String firstName = player.firstName!;
      String secondName = player.secondName!;
      String fullName = '$firstName $secondName';
      _playerNames.add(fullName);
    }

    notifyListeners();
  }

  // when player name is found, remove it from the list
  void removePlayerName(String playerName) {
    _playerNames.remove(playerName);
  }
}
