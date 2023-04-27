import 'package:animated_neumorphic/animated_neumorphic.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/helpers/widgets/leading_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:simple_progress_indicators/simple_progress_indicators.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:fplwordle/helpers/utils/navigator.dart';
import 'package:fplwordle/helpers/widgets/custom_btn.dart';
import 'package:fplwordle/helpers/widgets/custom_texts.dart';
import 'package:fplwordle/main.dart';
import 'package:fplwordle/models/profile.dart';
import 'package:fplwordle/models/user.dart';
import 'package:fplwordle/providers/auth_provider.dart';
import 'package:fplwordle/providers/profile_provider.dart';
import 'package:fplwordle/screens/signin_screen.dart';

import '../providers/sound_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AuthProvider _authProvider = AuthProvider();
  SoundsProvider _soundsProvider = SoundsProvider();
  // ProfileProvider _profileProvider = ProfileProvider();
  User? _user;
  bool _isLoggingOut = false;
  bool _isDesktop = false;

  @override
  void initState() {
    _authProvider = context.read<AuthProvider>();
    _soundsProvider = context.read<SoundsProvider>();
    // _profileProvider = context.read<ProfileProvider>();
    _user = _authProvider.user;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _isDesktop = MediaQuery.of(context).size.width > 600;
    Profile? profile = context.select<ProfileProvider, Profile?>((provider) => provider.profile);
    // if profile is null, assign fields to 0
    profile ??= Profile(
      gamesPlayed: 0,
      gamesWon: 0,
      gamesLost: 0,
      gamesAbandoned: 0,
      winStreak: 0,
      longestWinStreak: 0,
      playedToday: 0,
      playersFound: 0,
      correctFirstGuess: 0,
      noHintsUsed: 0,
      scoresShared: 0,
      multiplayerModePlayed: 0,
      winsInMultiplayerMode: 0,
      level: 1,
      xp: 0,
      difficulty: 1,
      achievements: Achievements(
        gamesPlayedX5: false,
        gamesPlayedX10: false,
        gamesPlayedX20: false,
        gamesInOneDayX3: false,
        winningStreakX5: false,
        playersFoundX25: false,
        playersFoundX50: false,
        correctFirstGuessX10: false,
        playAgameInMultiPlayerMode: false,
        scoresSharedX3: false,
        scoresSharedX10: false,
        noHintsUsedX5: false,
        winsInMultiplayerModeX5: false,
      ),
    );

    int gamesPlayed = profile.gamesPlayed!;
    int playedToday = profile.playedToday!;
    int winStreak = profile.longestWinStreak!;
    int playersFound = profile.playersFound!;
    int correctFirstGuesses = profile.correctFirstGuess!;
    int noHintsUsed = profile.noHintsUsed!;
    int scoresShared = profile.scoresShared!;
    int multiplayerModePlayed = profile.multiplayerModePlayed!;
    int winsInMultiplayerMode = profile.winsInMultiplayerMode!;

    List<Stat> stats = [
      Stat(name: "Played", value: profile.gamesPlayed!),
      Stat(name: "Won", value: profile.gamesWon!),
      Stat(name: "Lost", value: profile.gamesLost!),
      Stat(name: "Abandoned", value: profile.gamesAbandoned!),
      Stat(name: "Win Streak", value: profile.winStreak!),
      Stat(name: "Longest Win Streak", value: profile.longestWinStreak!),
    ];

    List<Achievement> achievements = [
      Achievement(
          name: "Games Played X5",
          description: profile.achievements!.gamesPlayedX5! ? "Completed" : "$gamesPlayed/5",
          unlocked: profile.achievements!.gamesPlayedX5!,
          progress: calculateAchievementProgress(gamesPlayed, 5)),
      Achievement(
          name: "Games Played X10",
          description: profile.achievements!.gamesPlayedX10! ? "Completed" : "$gamesPlayed/10",
          unlocked: profile.achievements!.gamesPlayedX10!,
          progress: calculateAchievementProgress(gamesPlayed, 10)),
      Achievement(
          name: "Games Played X20",
          description: profile.achievements!.gamesPlayedX20! ? "Completed" : "$gamesPlayed/20",
          unlocked: profile.achievements!.gamesPlayedX20!,
          progress: calculateAchievementProgress(gamesPlayed, 20)),
      Achievement(
          name: "Games In One Day X3",
          description: profile.achievements!.gamesInOneDayX3! ? "Completed" : "$playedToday/3",
          unlocked: profile.achievements!.gamesInOneDayX3!,
          progress: calculateAchievementProgress(playedToday, 3)),
      Achievement(
          name: "Winning Streak X5",
          description: profile.achievements!.winningStreakX5! ? "Completed" : "$winStreak/5",
          unlocked: profile.achievements!.winningStreakX5!,
          progress: calculateAchievementProgress(winStreak, 5)),
      Achievement(
          name: "Players Found X25",
          description: profile.achievements!.playersFoundX25! ? "Completed" : "$playersFound/25",
          unlocked: profile.achievements!.playersFoundX25!,
          progress: calculateAchievementProgress(playersFound, 25)),
      Achievement(
          name: "Players Found X50",
          description: profile.achievements!.playersFoundX50! ? "Completed" : "$playersFound/50",
          unlocked: profile.achievements!.playersFoundX50!,
          progress: calculateAchievementProgress(playersFound, 50)),
      // correctFirstGuessX10
      Achievement(
          name: "Correct First Guess X10",
          description: profile.achievements!.correctFirstGuessX10! ? "Completed" : "$correctFirstGuesses/10",
          unlocked: profile.achievements!.correctFirstGuessX10!,
          progress: calculateAchievementProgress(correctFirstGuesses, 10)),
      // playAgameInMultiPlayerMode,
      Achievement(
          name: "Play A Game In Multiplayer Mode",
          description: profile.achievements!.playAgameInMultiPlayerMode! ? "Completed" : "$multiplayerModePlayed/1",
          unlocked: profile.achievements!.playAgameInMultiPlayerMode!,
          progress: calculateAchievementProgress(multiplayerModePlayed, 1)),
      // winsInMultiplayerModeX5,
      Achievement(
          name: "Wins In Multiplayer Mode X5",
          description: profile.achievements!.winsInMultiplayerModeX5! ? "Completed" : "$winsInMultiplayerMode/5",
          unlocked: profile.achievements!.winsInMultiplayerModeX5!,
          progress: calculateAchievementProgress(winsInMultiplayerMode, 5)),
      // noHintsUsedX5,
      Achievement(
          name: "No Hints Used X5",
          description: profile.achievements!.noHintsUsedX5! ? "Completed" : "$noHintsUsed/5",
          unlocked: profile.achievements!.noHintsUsedX5!,
          progress: calculateAchievementProgress(noHintsUsed, 5)),
      // scoresSharedX3,
      Achievement(
          name: "Scores Shared X3",
          description: profile.achievements!.scoresSharedX3! ? "Completed" : "$scoresShared/3",
          unlocked: profile.achievements!.scoresSharedX3!,
          progress: calculateAchievementProgress(scoresShared, 3)),
      // scoresSharedX10;
      Achievement(
          name: "Scores Shared X10",
          description: profile.achievements!.scoresSharedX10! ? "Completed" : "$scoresShared/10",
          unlocked: profile.achievements!.scoresSharedX10!,
          progress: calculateAchievementProgress(scoresShared, 10)),
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
                  // TODO: implement shop screen (navigate or dialog)
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
          if (_isDesktop)
            Container(
              margin: const EdgeInsets.all(8),
              width: 150,
              child: customButton(context,
                  icon: Icons.logout,
                  text: _user == null ? 'Sign in' : 'Logout',
                  isLoading: _isLoggingOut, onTap: () async {
                if (_user == null) {
                  transitioner(const SignInScreen(), context);
                } else {
                  setState(() => _isLoggingOut = true);
                  await _authProvider.signOut();
                  setState(() => _isLoggingOut = false);
                  if (context.mounted) pushAndRemoveNavigator(const MyApp(), context);
                }
              }),
            )
        ],
      ),
      bottomNavigationBar: _isDesktop
          ? null
          : Container(
              height: 70,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // settings
                  InkWell(
                    onTap: () async {
                      await _soundsProvider.playClick();
                      // TODO: implement settings screen (navigate or dialog)
                    },
                    child: const AnimatedNeumorphicContainer(
                        depth: 0,
                        color: Palette.primary,
                        width: 50,
                        height: 50,
                        radius: 25.0,
                        child: Icon(Icons.settings, color: Colors.white, size: 35)),
                  ),
                  // logout/sign in
                  SizedBox(
                    width: 150,
                    child: customButton(context,
                        icon: Icons.logout,
                        text: _user == null ? 'Sign in' : 'Logout',
                        isLoading: _isLoggingOut, onTap: () async {
                      if (_user == null) {
                        transitioner(const SignInScreen(), context);
                      } else {
                        setState(() => _isLoggingOut = true);
                        await _authProvider.signOut();
                        setState(() => _isLoggingOut = false);
                        if (context.mounted) pushAndRemoveNavigator(const MyApp(), context);
                      }
                    }),
                  )
                ],
              ),
            ),
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
              // level and xp progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: headingText(
                        text: "Level ${profile.level.toString()}", fontSize: _isDesktop ? 25 : 18, variation: 2),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Palette.primary.withOpacity(0.2), width: 2),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]),
                    child: ProgressBar(
                        height: _isDesktop ? 15.0 : 10.0,
                        value: calculateProgress(profile.level!, profile.xp!),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.yellowAccent, Colors.deepOrange],
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 10),
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
                      children: achievements.sublist(0, 7).map((e) {
                        return achievementTile(e);
                      }).toList(),
                    ),
                    const SizedBox(width: 100),
                    // right column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: achievements.sublist(7, 13).map((e) {
                        return achievementTile(e);
                      }).toList(),
                    ),
                  ],
                )
            ],
          )),
    );
  }

  double calculateProgress(int level, int xp) {
    int xpNeeded = 10 * level;
    return xp / xpNeeded;
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
                    value: achievement.progress,
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
