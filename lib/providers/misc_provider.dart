import 'package:flutter/material.dart';

class MiscProvider extends ChangeNotifier {
  // store the full path of the website and web page
  String _fullPath = "";

  String get fullPath => _fullPath;

  void setFullPath(String fullpath) {
    _fullPath = fullpath;
  }
}
