import 'package:flutter/material.dart';
import 'package:fplwordle/helpers/widgets/custom_texts.dart';
import 'package:fplwordle/screens/onboarding_screen.dart' show Intro;
import '../helpers/widgets/leading_button.dart';

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
            "At midnight, 5 new hidden players will become available to find, their estimated value and preferred position listed at the top and bottom respectively. Your goal is to guess as many of the players as possible within 20 attempts.",
        image: "assets/tutorials/1.png"),
    Intro(
        title: "Guess a Player",
        subtitle: "Search & Auto-Complete",
        desc:
            'To guess a player, begin typing their name using the provided keyboard. As you type, suggestions will appear, use the arrows to navigate the suggestions. When your desired player is highlighted, hit the "Guess" button.',
        image: "assets/tutorials/2.png"),
    Intro(
        title: "Match Traits",
        subtitle: "Compare Player Guesses",
        desc:
            "If your guessed player has matching traits with the hidden players, such as nationality, club, age, or shirt number, those traits will be revealed. Use this information to help narrow down your future guesses.",
        image: "assets/tutorials/3.png"),
    Intro(
        title: "Find Players",
        subtitle: "Correct Guesses",
        desc:
            "A correct player guess will reveal their name and highlight them in green. However, if your guess is incorrect, regardless of whether the player has any matching traits, you will lose a life.",
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
            "To win the game, you must find all 5 hidden players before losing your 20 lives. Winning the game counts toward your win streak, provided you won the previous day's game. If you don't win, you can still make progress and receive awards for completing other challenges.",
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
    bool isDesktop = MediaQuery.of(context).size.width > 600;

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
                  TextButton(
                    onPressed: () {
                      _controller.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                    },
                    child: const Text(
                      "Previous",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_controller.page == _screens.length - 1) {
                        Navigator.of(context).pop();
                      } else {
                        _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return PageView.builder(
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
                ]);
              },
            );
          } else {
            return ListView.builder(
              itemCount: _screens.length,
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                return Container();
              },
            );
          }
        },
      ),
    );
  }
}
