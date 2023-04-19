import 'package:flutter/material.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:fplwordle/helpers/utils/navigator.dart';
import 'package:fplwordle/helpers/widgets/custom_texts.dart';
import 'package:fplwordle/screens/home_screen.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnBoardingSlider(
        headerBackgroundColor: Colors.transparent,
        finishButtonText: 'Proceed',
        finishButtonStyle: const FinishButtonStyle(
          backgroundColor: Palette.primary,
        ),
        skipTextButton: headingText(text: 'Skip', color: Colors.white, fontSize: 18),
        background: [
          Container(
            margin: const EdgeInsets.only(top: 30, left: 25),
            height: MediaQuery.of(context).size.height / 2.5,
            width: MediaQuery.of(context).size.width - 50,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/cards.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 30, left: 25),
            height: MediaQuery.of(context).size.height / 2.5,
            width: MediaQuery.of(context).size.width - 50,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/leaderboard.gif'),
                fit: BoxFit.fill,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 30, left: 25),
            height: MediaQuery.of(context).size.height / 2.5,
            width: MediaQuery.of(context).size.width - 50,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/share.gif'),
                fit: BoxFit.fill,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 30, left: 25),
            height: MediaQuery.of(context).size.height / 2.5,
            width: MediaQuery.of(context).size.width - 50,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/multiplayer.gif'),
                fit: BoxFit.fill,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 30, left: 25),
            height: MediaQuery.of(context).size.height / 2.5,
            width: MediaQuery.of(context).size.width - 50,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/premium.gif'),
                fit: BoxFit.fill,
              ),
            ),
          ),
        ],
        totalPage: 5,
        speed: 1.8,
        onFinish: () {
          AuthProvider authProvider = context.read<AuthProvider>();
          authProvider.completeOnboarding();
          transitioner(const HomeScreen(), context, replacement: true);

          // dialogHelper(context, 'Create Account or Login',
          //     'Your account is used to save your progress and to compete with other players.', [
          //   // login button
          //   TextButton(
          //       onPressed: () {
          //         authProvider.completeOnboarding();
          //         popNavigator(context, rootNavigator: true);
          //         pushReplacementNavigator(const LoginScreen(), context);
          //       },
          //       child: headingText(text: 'Sign In', color: Palette.primary, fontSize: 18)),
          //   // signup button
          //   TextButton(
          //       onPressed: () {
          //         authProvider.completeOnboarding();
          //         popNavigator(context, rootNavigator: true);
          //         pushReplacementNavigator(const SignupScreen(), context);
          //       },
          //       child: headingText(text: 'Sign Up', color: Palette.primary, fontSize: 18)),
          //   // skip button
          //   TextButton(
          //       onPressed: () {
          //         authProvider.completeOnboarding();
          //         popNavigator(context, rootNavigator: true);
          //         pushReplacementNavigator(const HomeScreen(), context);
          //       },
          //       child: headingText(text: 'Skip', color: Palette.primary, fontSize: 18)),
          // ]);
        },
        pageBodies: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 480,
                ),
                Center(
                  child: headingText(text: 'Welcome to FPL Wordle', color: Colors.white, fontSize: 24),
                ),
                const SizedBox(
                  height: 10,
                ),
                Center(
                  child: bodyText(text: 'Daily Puzzle \n20 lives \n3 hints', fontSize: 20, textAlign: TextAlign.center),
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 480,
                ),
                headingText(text: 'Leaderboard', color: Colors.white, fontSize: 24),
                const SizedBox(
                  height: 10,
                ),
                bodyText(text: 'View the ranks of other players', fontSize: 20, textAlign: TextAlign.center),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 480,
                ),
                headingText(text: 'Share', color: Colors.white, fontSize: 24),
                const SizedBox(
                  height: 10,
                ),
                bodyText(text: 'Share your score with friends', fontSize: 20, textAlign: TextAlign.center),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 480,
                ),
                headingText(text: 'Multiplayer Mode', color: Colors.white, fontSize: 24),
                const SizedBox(
                  height: 10,
                ),
                bodyText(text: 'Play with friends online', fontSize: 20, textAlign: TextAlign.center),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 480,
                ),
                headingText(text: 'Go Unlimited', color: Colors.white, fontSize: 24),
                const SizedBox(
                  height: 10,
                ),
                bodyText(
                    text: 'You can upgrade to enjoy unlimited number of puzzles in solo and multiplayer modes',
                    fontSize: 20,
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
