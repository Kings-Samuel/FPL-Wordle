import 'package:awesome_icons/awesome_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:fplwordle/helpers/utils/navigator.dart';
import 'package:fplwordle/helpers/widgets/custom_btn.dart';
import 'package:fplwordle/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg2.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withOpacity(0.8),
              padding: const EdgeInsets.all(30),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    // logo
                    Center(
                      child: Container(
                        height: 200,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/logo.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                      )
                          .animate(onComplete: (controller) => controller.repeat(min: 0.95, max: 1.0, period: 1000.ms))
                          .scale(
                            duration: 1000.ms,
                          ),
                    ),
                    const SizedBox(height: 40),
                    // buttons
                    Column(children: [
                      // play button
                      customButton(
                        context,
                        icon: Icons.play_arrow,
                        text: "Play",
                        onTap: () {},
                      ).animate(onPlay: (controller) => controller.repeat(period: 2000.ms)).shimmer(
                            delay: 1000.ms,
                            duration: 2000.ms,
                            color: Colors.white.withOpacity(0.8),
                          ),
                      const SizedBox(height: 20),
                      // multiplayer mode button
                      customButton(context,
                              icon: Icons.group,
                              text: "Multiplayer Mode",
                              backgroundColor: Palette.brightYellow,
                              onTap: () {})
                          .animate(onPlay: (controller) => controller.repeat(period: 2000.ms))
                          .shimmer(
                            delay: 1500.ms,
                            duration: 2000.ms,
                            color: Colors.white.withOpacity(0.8),
                          ),
                      const SizedBox(height: 20),
                      // // leaderboard button
                      // customButton(context,
                      //         icon: Icons.leaderboard,
                      //         text: "Leaderboard",
                      //         backgroundColor: Palette.cardHeaderGrey,
                      //         onTap: () {})
                      //     .animate(onPlay: (controller) => controller.repeat(period: 2000.ms))
                      //     .shimmer(
                      //       delay: 2000.ms,
                      //       duration: 2000.ms,
                      //       color: Colors.white.withOpacity(0.8),
                      //     ),
                      // const SizedBox(height: 20),
                      // shop button
                      customButton(context,
                              icon: FontAwesomeIcons.coins,
                              text: "Shop",
                              backgroundColor: Palette.vibrantRed,
                              onTap: () {})
                          .animate(onPlay: (controller) => controller.repeat(period: 2000.ms))
                          .shimmer(
                            delay: 2500.ms,
                            duration: 2000.ms,
                            color: Colors.white.withOpacity(0.8),
                          ),
                      const SizedBox(height: 20),
                      // how to play button
                      customButton(context,
                              icon: Icons.help, text: "How to Play", backgroundColor: Palette.richGreen, onTap: () {})
                          .animate(onPlay: (controller) => controller.repeat(period: 2000.ms))
                          .shimmer(
                            delay: 1000.ms,
                            duration: 2000.ms,
                            color: Colors.white.withOpacity(0.8),
                          ),
                      const SizedBox(height: 20),
                      // my profile button
                      customButton(context,
                              icon: Icons.person,
                              text: "My Profile",
                              backgroundColor: Palette.deepPurple,
                              onTap: () => transitioner(const ProfileScreen(), context))
                          .animate(onPlay: (controller) => controller.repeat(period: 2000.ms))
                          .shimmer(
                            delay: 3000.ms,
                            duration: 2000.ms,
                            color: Colors.white.withOpacity(0.8),
                          ),
                      const SizedBox(height: 20),
                      // settings button
                      customButton(context,
                              icon: Icons.settings,
                              text: "Settings",
                              backgroundColor: Colors.white,
                              onTap: () {},
                              textColor: Palette.primary)
                          .animate(onPlay: (controller) => controller.repeat(period: 2000.ms))
                          .shimmer(
                            delay: 3500.ms,
                            duration: 2000.ms,
                            color: Colors.grey.withOpacity(0.8),
                          ),
                    ]).animate().fadeIn(duration: 1000.ms)
                  ],
                ),
              ),
            )));
  }
}
