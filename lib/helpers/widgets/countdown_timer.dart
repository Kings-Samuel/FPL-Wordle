import 'package:flutter/material.dart';
import 'package:slide_countdown/slide_countdown.dart';

Widget countdownTimer(Duration duration) {
  return SlideCountdownSeparated(
      duration: duration,
      shouldShowDays: (_) => false,
      shouldShowHours: (_) => true,
      shouldShowMinutes: (_) => true,
      shouldShowSeconds: (_) => true,
      showZeroValue: true,
      textDirection: TextDirection.ltr,
      curve: Curves.easeIn);
}
