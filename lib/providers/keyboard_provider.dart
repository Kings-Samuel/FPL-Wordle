import 'dart:convert';
import 'package:flutter/material.dart';

class KeyboardProvider extends ChangeNotifier {
  String _input = '';
  String _typed = '';
  bool _isBackSpaceClicked = false;
  bool _isHintClicked = false;
  List<String> _playerNames = [];
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

  void useHint() {
    // TODO: implement useHint
    _isHintClicked = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () {
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
  }

  void useSuggestion(String suggestion) async {
    _input = suggestion.toUpperCase();
    _suggestions = [];
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1), () {
      _input = '';
      notifyListeners();
    });
  }

  // get all player names from player_names.json in assets
  void getPlayerNames(BuildContext context) async {
    final assetBundle = DefaultAssetBundle.of(context);
    final data = await assetBundle.loadString('assets/players_names.json');
    final body = json.decode(data);

    _playerNames = body.map<String>((json) => json['fullName'] as String).toList();

    notifyListeners();
  }
}
