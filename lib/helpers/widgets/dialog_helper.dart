import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:fplwordle/helpers/widgets/custom_texts.dart';

Future<void> _androidDialog(
  BuildContext context,
  String title,
  String content,
  List<Widget> actions,
) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.white.withOpacity(0.7),
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Palette.scaffold,
        title: Center(child: headingText(text: title)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: bodyText(text: content)),
          ],
        ),
        actions: actions,
      );
    },
  );
}

Future<void> _iosDialog(
  BuildContext context,
  String title,
  String content,
  List<Widget> actions,
) async {
  return showCupertinoDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Center(child: headingText(text: title, color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: bodyText(text: content, color: Colors.black, textAlign: TextAlign.center)),
          ],
        ),
        actions: actions,
      );
    },
  );
}

Future<void> dialogHelper(
  BuildContext context,
  String title,
  String content,
  List<Widget> actions,
) async {
  if (Platform.isIOS) {
    return _iosDialog(context, title, content, actions);
  } else {
    return _androidDialog(context, title, content, actions);
  }
}
