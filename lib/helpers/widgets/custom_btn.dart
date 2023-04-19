import 'package:animated_neumorphic/animated_neumorphic.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'custom_texts.dart';
import 'loading_animation.dart';

Widget customButton(
  BuildContext context, {
  required IconData icon,
  required String text,
  bool isLoading = false,
  required VoidCallback onTap,
  Color backgroundColor = Palette.primary,
  Color? textColor,
}) {
  if (isLoading == true) {
    return loadingAnimation();
  } else {
    return Center(
      child: InkWell(
        onTap: onTap,
        child: AnimatedNeumorphicContainer(
            depth: 0,
            color: backgroundColor,
            width: MediaQuery.of(context).size.width,
            height: 50,
            radius: 25.0,
            child: isLoading
                ? loadingAnimation()
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: textColor ?? Colors.white,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Container(
                          margin: const EdgeInsets.only(bottom: 5),
                          child: headingText(text: text, color: textColor ?? Colors.white, variation: 2,))
                    ],
                  )),
      ),
    );
  }
}
