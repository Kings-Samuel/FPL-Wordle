import 'package:flutter/material.dart';
import 'package:transitioner/transitioner.dart';

transitioner(Widget screen, BuildContext context, {bool replacement = false}) {
  Transitioner(
    context: context,
    child: screen,
    animation: AnimationType.slideBottom,
    duration: const Duration(milliseconds: 1500),
    replacement: replacement,
    curveType: CurveType.bounce,
  );
}

popNavigator(BuildContext context, {bool? rootNavigator}) {
  Navigator.of(context, rootNavigator: rootNavigator ?? false).pop();
}

pushAndRemoveNavigator(Widget screen, BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => screen), (route) => false);
}
