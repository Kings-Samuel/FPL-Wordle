import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transitioner/transitioner.dart';

transitioner(Widget screen, BuildContext context, String route, {bool replacement = false}) {
  if (kIsWeb) {
    context.go(route);
  } else {
    Transitioner(
      context: context,
      child: screen,
      animation: AnimationType.slideBottom,
      duration: const Duration(milliseconds: 500),
      replacement: replacement,
      curveType: CurveType.bounce,
    );
  }
}

popNavigator(BuildContext context, {bool? rootNavigator}) {
  Navigator.of(context, rootNavigator: rootNavigator ?? false).pop();
}

pushAndRemoveNavigator(Widget screen, BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => screen), (route) => false);
}
