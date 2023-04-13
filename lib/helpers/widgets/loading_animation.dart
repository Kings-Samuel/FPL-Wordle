import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

Widget loadingAnimation({Color color = Colors.white}) {
  return Center(child: LoadingAnimationWidget.threeArchedCircle(color: color, size: 30));
}