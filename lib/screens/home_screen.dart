import 'package:aesthetic_dialogs/aesthetic_dialogs.dart';
import 'package:animated_neumorphic/animated_neumorphic.dart';
import 'package:awesome_icons/awesome_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fplwordle/helpers/utils/navigator.dart';
import 'package:fplwordle/models/user.dart';
import 'package:fplwordle/screens/signin_screen.dart';
import 'package:provider/provider.dart';
import '../helpers/utils/color_palette.dart';
import '../helpers/widgets/countdown_timer.dart';
import '../helpers/widgets/custom_btn.dart';
import '../helpers/widgets/custom_texts.dart';
import '../providers/auth_provider.dart';
import '../providers/misc_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  AuthProvider _authProvider = AuthProvider();
  MiscProvider _miscProvider = MiscProvider();
  User? _user;
  final List<Button> _buttons = [
    // play
    Button(icon: Icons.play_arrow, title: "Play", onTap: () {}),
    // multi player mode
    Button(icon: Icons.people, title: "Multiplayer", onTap: () {}),
    // leader board
    // Button(icon: Icons.leaderboard, title: "Leaderboard", onTap: () {}),
    // shop
    Button(icon: FontAwesomeIcons.coins, title: "Shop", onTap: () {}),
    // how to play
    Button(icon: Icons.help, title: "How to play", onTap: () {}),
    // profile
    Button(icon: Icons.person, title: "Profile", onTap: () {}),
    // settings
    Button(icon: Icons.settings, title: "Settings", onTap: () {}),
  ];

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _miscProvider = context.read<MiscProvider>();
    _user = _authProvider.user;
  }

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
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width > 600 ? 50 : 20),
              child: SingleChildScrollView(
                child: Column(children: [
                  const SizedBox(height: 20),
                  // appbar
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    centerTitle: false,
                    title: appbarTitle(),
                    actions: [
                      // login
                      if (_user == null)
                        customButton(context,
                            icon: Icons.login,
                            text: "Sign In",
                            width: 120,
                            backgroundColor: Palette.scaffold,
                            onTap: () => transitioner(const SignInScreen(), context)),
                      const SizedBox(width: 15),
                      InkWell(
                          onTap: () {
                            print("clicked");
                          },
                          child: countdownTimer(_miscProvider.durationUntilNextGame))
                    ],
                  ),
                  const SizedBox(height: 30),
                  // logo
                  Center(
                    child: Container(
                      height: 200,
                      width: 300,
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
                  // _buttons
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return Column(
                          children: _buttons
                              .map((button) =>
                                  Container(margin: const EdgeInsets.only(bottom: 15), child: mobileButton(button)))
                              .toList(),
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _buttons.map((e) {
                            return Container(
                                margin: const EdgeInsets.only(right: 15),
                                child: InkWell(
                                  onTap: () => e.onTap,
                                  child: AnimatedNeumorphicContainer(
                                      depth: 0,
                                      color: Palette.scaffold,
                                      width: 100,
                                      height: 100,
                                      radius: 25.0,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(e.icon, color: Colors.white, size: 30),
                                          const SizedBox(height: 10),
                                          bodyText(text: e.title, color: Colors.white, fontSize: 20, bold: true),
                                        ],
                                      )),
                                ));
                          }).toList(),
                        );
                      }
                    },
                  ),
                ]),
              ),
            )));
  }

  Widget appbarTitle() {
    if (_user != null) {
      return Row(
        children: [
          // user name
          Center(child: bodyText(text: _user!.name!, color: Colors.white, fontSize: 20, bold: true)),
          const SizedBox(width: 8),
          // coins
          Center(child: Image.asset('assets/coin.png', height: 25, width: 25)),
          const SizedBox(width: 8),
          Center(
            child: bodyText(text: '14', color: Colors.white, fontSize: 20, bold: true),
          ),
        ],
      );
    } else {
      return const Text('');
    }
  }

  Widget mobileButton(Button button) {
    if (kIsWeb) {
      return customButton(
        context,
        icon: button.icon,
        text: button.title,
        backgroundColor: Palette.scaffold,
        onTap: () => button.onTap,
      );
    } else {
      return customButton(
        context,
        icon: button.icon,
        text: button.title,
        backgroundColor: Palette.scaffold,
        onTap: () => button.onTap,
      ).animate(onPlay: (controller) => controller.repeat(period: 2000.ms)).shimmer(
            delay: 1000.ms,
            duration: 2000.ms,
            color: Colors.white.withOpacity(0.8),
          );
    }
  }
}

class Button {
  String title;
  IconData icon;
  Function onTap;
  Button({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}
