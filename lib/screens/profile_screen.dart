import 'package:animated_neumorphic/animated_neumorphic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/consts/routes.dart';
import 'package:fplwordle/helpers/widgets/leading_button.dart';
import 'package:fplwordle/screens/home_screen.dart';
import 'package:fplwordle/screens/shop_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:simple_progress_indicators/simple_progress_indicators.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:fplwordle/helpers/utils/navigator.dart';
import 'package:fplwordle/helpers/widgets/custom_texts.dart';
import 'package:fplwordle/main.dart';
import 'package:fplwordle/models/profile.dart';
import 'package:fplwordle/models/user.dart';
import 'package:fplwordle/providers/auth_provider.dart';
import 'package:fplwordle/providers/profile_provider.dart';
import 'package:fplwordle/screens/signin_screen.dart';

import '../helpers/widgets/banner_ad_widget.dart';
import '../providers/sound_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  AuthProvider _authProvider = AuthProvider();
  SoundsProvider _soundsProvider = SoundsProvider();
  ProfileProvider _profileProvider = ProfileProvider();
  User? _user;
  bool _isDesktop = false;

  @override
  void initState() {
    _authProvider = context.read<AuthProvider>();
    _soundsProvider = context.read<SoundsProvider>();
    _profileProvider = context.read<ProfileProvider>();
    _user = _authProvider.user;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _isDesktop = MediaQuery.of(context).size.width > 600;
    Profile? profile = context.select<ProfileProvider, Profile?>((provider) => provider.profile);
    if (profile == null) _profileProvider.createLocalProfile();

    List<Stat> stats = [
      Stat(name: "Played", value: profile?.gamesPlayed ?? 0),
      Stat(name: "Won", value: profile?.gamesWon ?? 0),
      Stat(name: "Lost", value: profile?.gamesLost ?? 0),
      Stat(name: "Abandoned", value: profile?.gamesAbandoned ?? 0),
      // Stat(name: "Win Streak", value: profile.winStreak!),
      Stat(name: "Longest Win Streak", value: profile?.longestWinStreak ?? 0),
    ];

    List<Achievement> achievements = [
      Achievement(
          name: "Games Played X5",
          description: profile!.gamesPlayed! >= 5 ? "Completed" : "${profile.gamesPlayed}/5",
          unlocked: profile.gamesPlayed! >= 5,
          progress: profile.gamesPlayed! / 5),
      Achievement(
          name: "Games Played X10",
          description: profile.gamesPlayed! >= 10 ? "Completed" : "${profile.gamesPlayed}/10",
          unlocked: profile.gamesPlayed! >= 10,
          progress: profile.gamesPlayed! / 10),
      Achievement(
          name: "Games Played X20",
          description: profile.gamesPlayed! >= 20 ? "Completed" : "${profile.gamesPlayed}/20",
          unlocked: profile.gamesPlayed! >= 20,
          progress: profile.gamesPlayed! / 20),
      // Achievement(
      //     name: "Games In One Day X3",
      //     description: profile.achievements!.gamesInOneDayX3! ? "Completed" : "$playedToday/3",
      //     unlocked: profile.achievements!.gamesInOneDayX3!),
      Achievement(
          name: "Winnign Streak X5",
          description: profile.longestWinStreak! >= 5 ? "Completed" : "${profile.longestWinStreak}/5",
          unlocked: profile.longestWinStreak! >= 5,
          progress: profile.longestWinStreak! / 5),
      Achievement(
          name: "Players Found X25",
          description: profile.playersFound! >= 25 ? "Completed" : "${profile.playersFound}/25",
          unlocked: profile.playersFound! >= 25,
          progress: profile.playersFound! / 25),
      Achievement(
          name: "Players Found X50",
          description: profile.playersFound! >= 50 ? "Completed" : "${profile.playersFound}/50",
          unlocked: profile.playersFound! >= 50,
          progress: profile.playersFound! / 50),
      Achievement(
          name: "Correct First Guess X10",
          description: profile.correctFirstGuess! >= 10 ? "Completed" : "${profile.correctFirstGuess}/10",
          unlocked: profile.correctFirstGuess! >= 10,
          progress: profile.correctFirstGuess! / 10),
      // Achievement(
      //     name: "Play A Game In Multiplayer Mode",
      //     description: profile.achievements!.playAgameInMultiPlayerMode! ? "Completed" : "$multiplayerModePlayed/1",
      //     unlocked: profile.achievements!.playAgameInMultiPlayerMode!,
      //     progress: calculateAchievementProgress(multiplayerModePlayed, 1)),
      // Achievement(
      //     name: "Wins In Multiplayer Mode X5",
      //     description: profile.achievements!.winsInMultiplayerModeX5! ? "Completed" : "$winsInMultiplayerMode/5",
      //     unlocked: profile.achievements!.winsInMultiplayerModeX5!,
      //     progress: calculateAchievementProgress(winsInMultiplayerMode, 5)),
      Achievement(
          name: "No Hints Used X5",
          description: profile.noHintsUsed! >= 5 ? "Completed" : "${profile.noHintsUsed}/5",
          unlocked: profile.noHintsUsed! >= 5,
          progress: profile.noHintsUsed! / 5),
      Achievement(
          name: "Scores Shared X3",
          description: profile.scoresShared! >= 3 ? "Completed" : "${profile.scoresShared}/3",
          unlocked: profile.scoresShared! >= 3,
          progress: profile.scoresShared! / 3),
      Achievement(
          name: "Scores Shared X10",
          description: profile.scoresShared! >= 10 ? "Completed" : "${profile.scoresShared}/10",
          unlocked: profile.scoresShared! >= 10,
          progress: profile.scoresShared! / 10),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: leadingButton(context),
        actions: [
          // coins button
          if (_user != null)
            Container(
              margin: const EdgeInsets.all(8),
              child: InkWell(
                onTap: () async {
                  await _soundsProvider.playClick();
                  if (mounted) transitioner(const ShopScreen(), context, Routes.shop);
                },
                child: AnimatedNeumorphicContainer(
                    depth: 0,
                    color: Palette.primary,
                    height: 40,
                    radius: 25.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset('assets/coin.png', height: 25, width: 25),
                          const SizedBox(width: 8),
                          bodyText(text: profile.coins.toString(), color: Colors.white, fontSize: 20, bold: true),
                          const SizedBox(width: 8),
                          Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Palette.scaffold),
                              child: const Icon(Icons.add, color: Colors.white, size: 25))
                        ],
                      ),
                    )),
              ),
            ),
          const SizedBox(width: 10),
          // logout/sign in
          InkWell(
              child: const Icon(Icons.logout),
              onTap: () async {
                if (_user == null) {
                  transitioner(const SignInScreen(), context, Routes.signin);
                } else {
                  await _authProvider.signOut();
                  if (context.mounted && !kIsWeb) {
                    pushAndRemoveNavigator(const MyApp(), context);
                  } else {
                    transitioner(const HomeScreen(), context, Routes.home);
                  }
                }
              })
        ],
      ),
      bottomNavigationBar: bannerAdWidget(profile.isPremiumMember ?? false),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // profile info
              if (_user == null)
                Align(
                  alignment: _isDesktop ? Alignment.center : Alignment.centerLeft,
                  child: RichText(
                      textAlign: _isDesktop ? TextAlign.center : TextAlign.left,
                      text: TextSpan(
                          text: 'You are not signed in \n',
                          style: GoogleFonts.ntr(
                              color: Colors.grey, fontWeight: FontWeight.bold, fontSize: _isDesktop ? 18 : 14),
                          children: [
                            TextSpan(
                                text: 'Sign in to sync your progress and access many more features',
                                style: GoogleFonts.ntr(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: _isDesktop ? 18 : 14,
                                )),
                          ])),
                )
              else
                Column(
                  children: [
                    Center(
                      child: RandomAvatar(_user!.name!, height: 100, width: 100, allowDrawingOutsideViewBox: true),
                    ),
                    const SizedBox(height: 10),
                    bodyText(text: _user!.name!, fontSize: 20, bold: true),
                    bodyText(text: _user!.email!),
                  ],
                ),
              const SizedBox(height: 10),
              // level and totalXP progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: headingText(
                        text: "Level ${_profileProvider.getLevel()}", fontSize: _isDesktop ? 25 : 18, variation: 2),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Palette.primary.withOpacity(0.2), width: 2),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]),
                    child: ProgressBar(
                        height: _isDesktop ? 15.0 : 10.0,
                        value: _profileProvider.getLevelXP(),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.yellowAccent, Colors.deepOrange],
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // highscore
              AnimatedNeumorphicContainer(
                depth: 0,
                color: Palette.scaffold,
                width: _isDesktop ? 150 : 100,
                height: _isDesktop ? 150 : 100,
                radius: 20.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(child: headingText(text: 'HIGHSCORE', fontSize: _isDesktop ? 25 : 20, variation: 1)),
                    const SizedBox(height: 10),
                    Center(child: headingText(text: profile.highScore.toString(), fontSize: _isDesktop ? 35 : 30)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              // stats grid view
              if (_isDesktop)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: stats.map((e) {
                    return Container(margin: const EdgeInsets.only(right: 15), child: statCard(stat: e));
                  }).toList(),
                )
              else
                GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: stats.map((e) {
                      return statCard(stat: e);
                    }).toList()),
              const SizedBox(height: 20),
              Divider(color: Palette.primary.withOpacity(0.2), thickness: 2),
              const SizedBox(height: 10),
              // achievements
              Center(child: headingText(text: 'ACHIEVEMENTS', fontSize: _isDesktop ? 35 : 25, variation: 1)),
              const SizedBox(height: 10),
              if (!_isDesktop)
                Column(
                  children: achievements.map((e) {
                    return achievementTile(e);
                  }).toList(),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // left column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: achievements.sublist(0, 6).map((e) {
                        return achievementTile(e);
                      }).toList(),
                    ),
                    const SizedBox(width: 100),
                    // right column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: achievements.sublist(6, 10).map((e) {
                        return achievementTile(e);
                      }).toList(),
                    ),
                  ],
                )
            ],
          )),
    );
  }

  double calculateAchievementProgress(int current, int max) {
    double result = current / max;
    if (result > 1.0) result = 1.0;
    return result;
  }

  Widget statCard({required Stat stat}) {
    return AnimatedNeumorphicContainer(
      depth: 0,
      color: Palette.scaffold,
      width: _isDesktop ? 120 : 80,
      height: _isDesktop ? 120 : 80,
      radius: 20.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: bodyText(text: stat.name, fontSize: 18, bold: true, textAlign: TextAlign.center)),
          const SizedBox(height: 5),
          Center(child: headingText(text: stat.value.toString(), fontSize: 25, variation: 3)),
        ],
      ),
    );
  }

  Widget achievementTile(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // achievement name and progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: bodyText(text: achievement.name, fontSize: _isDesktop ? 18 : 16, bold: true)),
              const SizedBox(height: 5),
              // progress bar
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    border: Border.all(color: Palette.primary.withOpacity(0.2), width: 2),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]),
                child: ProgressBar(
                    height: 10.0,
                    value: achievement.unlocked ? 1 : achievement.progress,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.yellowAccent, Colors.deepOrange],
                    )),
              ),
            ],
          ),
          SizedBox(width: _isDesktop ? 50 : 10),
          if (achievement.unlocked)
            headingText(text: "COMPLETED", fontSize: _isDesktop ? 18 : 16, variation: 3)
          else
            bodyText(
                text: achievement.description, fontSize: _isDesktop ? 18 : 16, bold: true, textAlign: TextAlign.center)
        ],
      ),
    );
  }
}

class Stat {
  String name;
  int value;

  Stat({required this.name, required this.value});
}

class Achievement {
  String name;
  String description;
  bool unlocked;
  double progress;

  Achievement({
    required this.name,
    required this.description,
    required this.unlocked,
    required this.progress,
  });
}
