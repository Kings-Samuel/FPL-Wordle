import 'package:animated_neumorphic/animated_neumorphic.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/consts/routes.dart';
import 'package:fplwordle/helpers/widgets/custom_texts.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../helpers/utils/color_palette.dart';
import '../helpers/utils/navigator.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController(initialPage: 0);
  bool _canShow = false;
  final List<Intro> _introList = [
    Intro(title: 'Welcome to FPL Wordle', desc: 'Daily Puzzle \n20 lives \n3 hints', image: 'assets/cards.png'),
    // Intro(title: 'Leaderboard', desc: 'View the ranks of other players', image: 'assets/leaderboard.gif'),
    Intro(title: 'Share', desc: 'Share your score with friends', image: 'assets/share.gif'),
    Intro(title: 'Multiplayer Mode', desc: 'Play with friends online', image: 'assets/multiplayer.gif'),
    Intro(
        title: 'Go Unlimited',
        desc: 'You can upgrade to enjoy unlimited number of puzzles in solo and multiplayer modes',
        image: 'assets/premium.gif'),
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

  void onFinished(BuildContext context) {
    var authProvider = context.read<AuthProvider>();
    authProvider.completeOnboarding();
    transitioner(const HomeScreen(), context, Routes.home, replacement: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: MediaQuery.of(context).size.width < 600
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  Visibility(
                    visible: _canShow && _controller.page != _introList.length - 1,
                    child: TextButton(
                      onPressed: () => _controller.jumpToPage(_introList.length - 1),
                      child: headingText(text: 'Skip', color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              )
            : null,
        bottomNavigationBar: MediaQuery.of(context).size.width < 600
            ? !_canShow
                ? null
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.bounceInOut,
                    height: 160,
                    padding: const EdgeInsets.all(25),
                    width: MediaQuery.of(context).size.width,
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // finish button
                        Visibility(
                          visible: _controller.page == _introList.length - 1,
                          child: InkWell(
                            onTap: () => onFinished(context),
                            child: AnimatedNeumorphicContainer(
                                depth: 0,
                                color: Palette.primary,
                                width: MediaQuery.of(context).size.width - 100,
                                height: 50,
                                radius: 16.0,
                                child: Center(
                                  child: headingText(text: 'Continue', color: Colors.white),
                                )),
                          ),
                        ),
                        const Spacer(),
                        // buttons and indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // back button
                            Visibility(
                              visible: _canShow && _controller.page != 0,
                              child: InkWell(
                                onTap: () {
                                  _controller.previousPage(
                                      duration: const Duration(milliseconds: 500), curve: Curves.ease);
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  height: 40,
                                  width: 40,
                                  padding: const EdgeInsets.only(left: 5),
                                  decoration: BoxDecoration(
                                    color: Palette.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(child: Icon(Icons.arrow_back_ios, color: Colors.white)),
                                ),
                              ),
                            ),
                            const Spacer(),
                            // page indicator
                            SmoothPageIndicator(
                                controller: _controller,
                                count: _introList.length,
                                effect: const ExpandingDotsEffect(
                                  dotWidth: 10,
                                  dotHeight: 10,
                                ),
                                onDotClicked: (index) {
                                  _controller.animateToPage(index,
                                      duration: const Duration(milliseconds: 500), curve: Curves.ease);
                                }),
                            const Spacer(),
                            // next button
                            Visibility(
                              visible: _canShow && _controller.page != _introList.length - 1,
                              child: InkWell(
                                onTap: () {
                                  _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease);
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  height: 40,
                                  width: 40,
                                  padding: const EdgeInsets.only(left: 5),
                                  decoration: BoxDecoration(
                                    color: Palette.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(child: Icon(Icons.arrow_forward_ios, color: Colors.white)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
            : null,
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return mobileView(context);
            } else {
              return desktopView(context);
            }
          },
        ));
  }

  Widget mobileView(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: _introList.length,
      itemBuilder: (context, index) {
        Intro intro = _introList[index];

        return Column(children: [
          const SizedBox(
            height: 30,
          ),
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
          headingText(text: intro.title, color: Colors.white, fontSize: 24),
          const SizedBox(
            height: 10,
          ),
          bodyText(text: intro.desc, fontSize: 20, textAlign: TextAlign.center),
        ]);
      },
    );
  }

  Widget desktopView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 400,
          child: Center(
            child: ListView.separated(
              shrinkWrap: true,
              separatorBuilder: (context, index) => const SizedBox(width: 25),
              scrollDirection: Axis.horizontal,
              itemCount: _introList.length,
              itemBuilder: (context, index) {
                Intro intro = _introList[index];

                return Center(
                  child: AnimatedNeumorphicContainer(
                      depth: 0,
                      color: Palette.primary,
                      width: 250,
                      radius: 25.0,
                      child: Container(
                          padding: const EdgeInsets.all(10.0),
                          width: 250,
                          height: 360,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                intro.image,
                                height: 200,
                                width: 200,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              headingText(
                                  text: intro.title, color: Colors.white, fontSize: 22, textAlign: TextAlign.center),
                              const SizedBox(
                                height: 10,
                              ),
                              bodyText(text: intro.desc, fontSize: 16, textAlign: TextAlign.center),
                            ],
                          ))),
                );
              },
            ),
          ),
        ),
        const SizedBox(
          height: 50,
        ),
        Center(
          child: AnimatedNeumorphicContainer(
              depth: 0,
              color: Palette.primary,
              width: 250,
              height: 50,
              radius: 16.0,
              child: InkWell(
                onTap: () => onFinished(context),
                child: Center(
                  child: headingText(text: 'Continue', color: Colors.white),
                ),
              )),
        )
      ],
    );
  }
}

class Intro {
  String title, desc, image;
  String? subtitle;

  Intro({required this.title, required this.desc, required this.image, this.subtitle});
}
