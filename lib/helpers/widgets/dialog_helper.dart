import 'package:flutter/material.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:fplwordle/helpers/widgets/custom_texts.dart';

Future<void> customDialog(
    {required BuildContext context,
    required String title,
    required List<Widget> contentList,
    List<Widget> actions = const []}) async {
  await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              color: Palette.primary,
              width: 3.0,
            ),
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: Palette.scaffold,
          contentPadding: const EdgeInsets.all(20),
          titlePadding: const EdgeInsets.all(20),
          title: Center(child: headingText(text: title, fontSize: 22, color: Palette.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: contentList,
          ),
          actions: actions,
        );
      });
}
