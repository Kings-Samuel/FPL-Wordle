import 'package:flutter/material.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:fplwordle/helpers/widgets/custom_texts.dart';
import 'package:fplwordle/screens/onboarding_screen.dart' show Intro;
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../helpers/widgets/banner_ad_widget.dart';
import '../helpers/widgets/leading_button.dart';
import '../models/profile.dart';
import '../providers/profile_provider.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController(initialPage: 0);
  bool _canShow = false;
  final List<Intro> _screens = [
    Intro(
        title: "Start the Game",
        subtitle: "5 hidden players",
        desc:
            "Five new hidden players will be provided to the game at 17:00 UTC every day, with their favorite position and likely worth listed at the top and bottom, respectively. Depending on the difficulty level you select, your objective is to correctly predict as many players as you can in 20, 15, or 10 attempts.",
        image: "assets/tutorials/1.png"),
    Intro(
        title: "Guess a Player",
        subtitle: "Search & Auto-Complete",
        desc:
            "Start entering a player's name on the given keyboard and try to guess who it is. Use the arrows to move through the recommendations that display as you type. Click on the palyer name once your desired player is highlighted.",
        image: "assets/tutorials/2.png"),
    Intro(
        title: "Match Traits",
        subtitle: "Compare Player Guesses",
        desc:
            "Players' traits will be displayed if any characteristics, such as nationality, club, age, or shirt number, match those of the concealed players. This helps to narrow down your future guesses",
        image: "assets/tutorials/3.png"),
    Intro(
        title: "Find Players",
        subtitle: "Correct Guesses",
        desc:
            "When a player's guess is correct, their name is revealed and they are highlighted in green. You are going to lose a life if your guess is wrong, regardless of whether the player possesses any attributes that match your prediction.",
        image: "assets/tutorials/4.png"),
    Intro(
        title: "Use Hints",
        subtitle: "Reveal Hidden Traits",
        desc:
            'At any point in the game, you can use one of 3 hints to reveal a hidden trait. Click the "Hint" button and select the trait to uncover. Hints can be crucial for winning, be strategic when using them.',
        image: "assets/tutorials/5.png"),
    Intro(
        title: "Win the Game",
        subtitle: "Streaks & Awards",
        desc:
            "To win the game, you must find all 5 hidden players before losing all your lives. Winning the game counts toward your win streak, provided you won the previous day's game. If you don't win, you can still make progress and receive awards for completing other challenges.",
        image: "assets/tutorials/6.png")
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(microseconds: 800), () {
      setState(() {
        _canShow = true;
      });
    });
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    Profile? profile = context.select<ProfileProvider, Profile?>((provider) => provider.profile);

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: leadingButton(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: headingText(
                text: "HOW TO PLAY",
              ),
            ),
            bottomNavigationBar: !_canShow
                ? null
                : SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // previous button
                        TextButton(
                          onPressed: () {
                            _controller.previousPage(
                                duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                          },
                          child: const Text(
                            "Previous",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        // inidicator
                        SmoothPageIndicator(
                            controller: _controller,
                            count: _screens.length,
                            effect: const ExpandingDotsEffect(
                              dotWidth: 10,
                              dotHeight: 10,
                            ),
                            onDotClicked: (index) {
                              _controller.animateToPage(index,
                                  duration: const Duration(milliseconds: 500), curve: Curves.ease);
                            }),
                        // next button
                        TextButton(
                          onPressed: () {
                            if (_controller.page == _screens.length - 1) {
                              Navigator.of(context).pop();
                            } else {
                              _controller.nextPage(
                                  duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                            }
                          },
                          child: Text(
                            _controller.page == _screens.length - 1 ? "Finish" : "Next",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            body: PageView.builder(
              controller: _controller,
              itemCount: _screens.length,
              itemBuilder: (context, index) {
                Intro intro = _screens[index];

                return Column(children: [
                  const SizedBox(
                    height: 30,
                  ),
                  // image
                  Center(
                    child: Image.asset(
                      intro.image,
                      height: 350,
                      width: 350,
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  // title
                  headingText(text: intro.title, color: Colors.white, fontSize: 24),
                  const SizedBox(
                    height: 10,
                  ),
                  // subtitle
                  bodyText(text: intro.subtitle!, color: Colors.grey, fontSize: 22),
                  const SizedBox(
                    height: 10,
                  ),
                  // description
                  bodyText(text: intro.desc, fontSize: 20, textAlign: TextAlign.center),
                  // banner ads
                  bannerAdWidget(profile?.isPremiumMember ?? false),
                ]);
              },
            ));
      } else {
        return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: leadingButton(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: headingText(
                text: "HOW TO PLAY",
              ),
            ),
            body: ListView.builder(
              itemCount: _screens.length,
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                Intro screen = _screens[index];

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(35),
                  alignment: Alignment.center,
                  color: index % 2 == 0 ? Colors.transparent : Palette.cardHeaderGrey,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // image (only on odd indexes)
                        if (index % 2 != 0)
                          Image.asset(
                            screen.image,
                            height: 350,
                            width: 350,
                          ),
                        if (index % 2 != 0)
                          const SizedBox(
                            width: 50,
                          ),
                        // content
                        Expanded(
                          child: Column(
                            children: [
                              // title
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: headingText(
                                      text: screen.title,
                                      color: Colors.white,
                                      fontSize: 24,
                                      textAlign: TextAlign.left)),
                              const SizedBox(
                                height: 10,
                              ),
                              // subtitle
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: bodyText(
                                      text: screen.subtitle!,
                                      color: Colors.grey,
                                      fontSize: 22,
                                      textAlign: TextAlign.left)),
                              const SizedBox(
                                height: 10,
                              ),
                              // description
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: bodyText(text: screen.desc, fontSize: 20, textAlign: TextAlign.left)),
                            ],
                          ),
                        ),
                        if (index % 2 == 0)
                          const SizedBox(
                            width: 50,
                          ),
                        // image (only on even indexes)
                        if (index % 2 == 0)
                          Image.asset(
                            screen.image,
                            height: 350,
                            width: 350,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ));
      }
    });
  }
}
