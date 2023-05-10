import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../consts/routes.dart';
import '../helpers/utils/color_palette.dart';
import '../helpers/widgets/custom_btn.dart';
import '../helpers/widgets/custom_texts.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // image
          Center(
            child: Container(
              height: 350,
              width: 500,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                image: DecorationImage(
                  image: AssetImage('assets/404.gif'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // heading
          Center(child: headingText(text: "PAGE NOT FOUND", fontSize: 35)),
          const SizedBox(height: 20),
          // body text
          SizedBox(
            width: 500,
            child: bodyText(
                text: "Sorry! The page you are looking for does not exist.",
                fontSize: 20,
                textAlign: TextAlign.center,
                bold: true),
          ),
          const SizedBox(height: 30),
          // button
          Center(
            child: SizedBox(
              width: 300,
              child: customButton(context,
                  backgroundColor: Palette.primary,
                  icon: Icons.home_rounded,
                  text: "RETURN HOME",
                  onTap: () => context.go(Routes.home)),
            ),
          )
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400));
  }
}
