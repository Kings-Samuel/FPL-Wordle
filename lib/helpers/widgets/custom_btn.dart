// ignore_for_file: invalid_use_of_protected_member
import 'package:animated_neumorphic/animated_neumorphic.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:hovering/hovering.dart';
import 'package:provider/provider.dart';
import '../../providers/sound_provider.dart';
import 'custom_texts.dart';
import 'loading_animation.dart';

Widget customButton(BuildContext context,
    {required IconData icon,
    required String text,
    bool isLoading = false,
    required VoidCallback onTap,
    Color backgroundColor = Palette.primary,
    bool useSound = true,
    Color? textColor,
    double? width}) {
  if (isLoading == true) {
    return loadingAnimation();
  } else {
    return Center(
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        radius: 0.0,
        onTap: () async {
          if (useSound) await context.read<SoundsProvider>().playClick();
          onTap();
        },
        child: HoverWidget(
          hoverChild: AnimatedNeumorphicContainer(
              depth: 0.0,
              color: backgroundColor.withOpacity(0.5),
              width: width ?? MediaQuery.of(context).size.width * 0.9,
              height: 53.0,
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
                        headingText(text: text, color: textColor ?? Colors.white, variation: 1, fontSize: 20)
                      ],
                    )),
          onHover: (event) {},
          child: AnimatedNeumorphicContainer(
              depth: 0.0,
              color: backgroundColor,
              width: width ?? MediaQuery.of(context).size.width * 0.9,
              height: 50.0,
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
                        headingText(text: text, color: textColor ?? Colors.white, variation: 1, fontSize: 20)
                      ],
                    )),
        ),
      ),
    );
  }
}
