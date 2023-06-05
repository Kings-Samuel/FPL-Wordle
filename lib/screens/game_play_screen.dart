import 'package:flutter/material.dart';
import 'package:fplwordle/consts/routes.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:fplwordle/helpers/utils/navigator.dart';
import 'package:fplwordle/helpers/widgets/custom_texts.dart';
import 'package:fplwordle/helpers/widgets/leading_button.dart';
import 'package:fplwordle/models/single_mode_puzzle.dart';
import 'package:fplwordle/providers/keyboard_provider.dart';
import 'package:fplwordle/screens/profile_screen.dart';
import 'package:fplwordle/screens/shop_screen.dart';
import 'package:provider/provider.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:simple_progress_indicators/simple_progress_indicators.dart';

import '../models/profile.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/single_mode_game_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/sound_provider.dart';

class GamePlayScreen extends StatefulWidget {
  const GamePlayScreen({Key? key}) : super(key: key);

  @override
  GamePlayScreenState createState() => GamePlayScreenState();
}

class GamePlayScreenState extends State<GamePlayScreen> {
  KeyboardProvider _keyboardProvider = KeyboardProvider();
  final List<String> _line1Letters = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
  final List<String> _line2Letters = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
  final List<String> _line3Letters = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];
  final _controller = ScrollController();
  AuthProvider _authProvider = AuthProvider();
  SoundsProvider _soundsProvider = SoundsProvider();
  ProfileProvider _profileProvider = ProfileProvider();
  SingleModeGameProvider _gameProvider = SingleModeGameProvider();
  User? _user;

  @override
  void initState() {
    super.initState();
    _keyboardProvider = context.read<KeyboardProvider>();
    _keyboardProvider.getPlayerNames(context);
    _authProvider = context.read<AuthProvider>();
    _soundsProvider = context.read<SoundsProvider>();
    _profileProvider = context.read<ProfileProvider>();
    _gameProvider = context.read<SingleModeGameProvider>();
    _user = _authProvider.user;
    _loadPuzzle();
  }

  Future<void> _loadPuzzle() async {
    bool isGameInSession = await _gameProvider.isGameInSession(_profileProvider);

    if (isGameInSession && mounted) {
      _gameProvider.loadGameInSession();
    } else {
      _gameProvider.loadNewGame(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 600;
    // keyboard provider
    bool isBackspaceClicked =
        context.select((KeyboardProvider keyboardProvider) => keyboardProvider.isBackSpaceClicked);
    bool isHintClicked = context.select((KeyboardProvider keyboardProvider) => keyboardProvider.isHintClicked);
    String typedSelector = context.select((KeyboardProvider keyboardProvider) => keyboardProvider.typed);
    String input = context.select((KeyboardProvider keyboardProvider) => keyboardProvider.input);
    List<String> suggestions = context.select((KeyboardProvider keyboardProvider) => keyboardProvider.suggestions);
    // profile provider
    Profile? profile = context.select<ProfileProvider, Profile?>((provider) => provider.profile);
    if (profile == null) _profileProvider.createLocalProfile();
    // game provider
    SingleModePuzzle? puzzle = context.select<SingleModeGameProvider, SingleModePuzzle?>((provider) => provider.puzzle);

    return Scaffold(
        backgroundColor: Palette.scaffold,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: leadingButton(context),
          title: Row(
            mainAxisAlignment: isDesktop ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
            children: [
              // profile
              InkWell(
                onTap: () => transitioner(const ProfileScreen(), context, Routes.profile),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    children: [
                      // profile avatar
                      if (_user != null)
                        Row(
                          children: [
                            Center(
                              child:
                                  RandomAvatar(_user!.name!, height: 40, width: 40, allowDrawingOutsideViewBox: true),
                            ),
                            const SizedBox(width: 5),
                          ],
                        ),
                      // xp and level
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Center(
                            child: headingText(
                                text: "Level ${profile!.level.toString()}",
                                fontSize: isDesktop ? 18 : 16,
                                variation: 2),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                                border: Border.all(color: Palette.primary.withOpacity(0.2), width: 2),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]),
                            child: ProgressBar(
                                height: 7,
                                width: 70.0,
                                value: calculateProgress(profile.level!, profile.xp!),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.yellowAccent, Colors.deepOrange],
                                )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isDesktop) const SizedBox(width: 200),
              // others
              Container(
                padding: const EdgeInsets.all(5),
                child: Row(
                  children: [
                    // lives
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red),
                        const SizedBox(width: 2.5),
                        headingText(text: puzzle?.lives.toString() ?? "0", fontSize: isDesktop ? 18 : 16),
                      ],
                    ),
                    SizedBox(width: isDesktop ? 15 : 7),
                    // hints
                    Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.yellow),
                        const SizedBox(width: 2.5),
                        headingText(text: puzzle?.hints.toString() ?? "0", fontSize: isDesktop ? 18 : 16),
                      ],
                    ),
                    SizedBox(width: isDesktop ? 15 : 7),
                    // coins
                    InkWell(
                      onTap: () => transitioner(const ShopScreen(), context, Routes.shop),
                      child: Row(
                        children: [
                          Image.asset("assets/coin.png", height: 20, width: 20),
                          const SizedBox(width: 2.5),
                          headingText(text: "100", fontSize: isDesktop ? 18 : 16),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        body: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Spacer(),
          // keyboard
          Center(
            child: Container(
              height: 295,
              width: isDesktop ? 550 : double.infinity,
              padding:
                  isDesktop ? const EdgeInsets.all(15) : const EdgeInsets.only(top: 10, bottom: 20, left: 5, right: 5),
              color: Palette.cardHeaderGrey,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // ** INPUT ** //
                  if (input.isEmpty)
                    Center(child: bodyText(text: "Type in a PLAYER NAME", color: Colors.grey, fontSize: 18))
                  else
                    Center(child: bodyText(text: input, color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 15),
                  // ** SUGGESTIONS ** //
                  if (input.isNotEmpty && input != " ")
                    Container(
                      height: 50,
                      width: isDesktop ? 550 : double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // previous
                          if (suggestions.isNotEmpty && _controller.hasClients)
                            Center(
                              child: IconButton(
                                onPressed: () => _controller.animateTo(
                                  _controller.offset - 100,
                                  curve: Curves.easeOut,
                                  duration: const Duration(milliseconds: 300),
                                ),
                                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                              ),
                            ),
                          const SizedBox(width: 5),
                          // suggestions
                          Expanded(
                            child: Center(
                              child: ListView.builder(
                                controller: _controller,
                                scrollDirection: Axis.horizontal,
                                itemCount: suggestions.length,
                                itemBuilder: (context, index) {
                                  String suggestion = suggestions[index];
                                  return Center(
                                    child: InkWell(
                                      onTap: () => _keyboardProvider.useSuggestion(suggestion),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 5),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Palette.cardHeaderGrey,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: bodyText(
                                            text: suggestion.toUpperCase(),
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 18,
                                            bold: true),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          // next
                          if (suggestions.isNotEmpty && _controller.hasClients)
                            Center(
                              child: IconButton(
                                onPressed: () => _controller.animateTo(
                                  _controller.offset + 100,
                                  curve: Curves.easeOut,
                                  duration: const Duration(milliseconds: 300),
                                ),
                                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  // ** KEYBOARD ** //
                  // line 1
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      _line1Letters.length,
                      (index) => Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                              left: index == 0 ? 0 : 2, right: index == _line1Letters.length - 1 ? 0 : 2),
                          child: _key(_line1Letters[index]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // line 2
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      _line2Letters.length,
                      (index) => Expanded(
                          child: Container(
                              margin: EdgeInsets.only(
                                  left: index == 0 ? 0 : 2, right: index == _line1Letters.length - 1 ? 0 : 2),
                              child: _key(_line2Letters[index]))),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // line 3
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _key("-", width: 25),
                    const SizedBox(width: 2),
                    _key("'", width: 25),
                    const SizedBox(width: 2),
                    ...List.generate(
                      _line3Letters.length,
                      (index) => Expanded(
                          child: Container(
                              margin: EdgeInsets.only(
                                  left: index == 0 ? 0 : 2, right: index == _line1Letters.length - 1 ? 0 : 2),
                              child: _key(_line3Letters[index]))),
                    ),
                    const SizedBox(width: 2),
                    // backspace
                    InkWell(
                      onTap: () => _keyboardProvider.backSpace(),
                      onLongPress: () => _keyboardProvider.clearInput(),
                      child: Container(
                        width: 55,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isBackspaceClicked ? Palette.primary : Palette.scaffold,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Center(child: Icon(Icons.backspace, color: Colors.white)),
                      ),
                    ),
                  ]),
                  // line 4
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      // hint button
                      InkWell(
                        onTap: () => _keyboardProvider.useHint(),
                        child: Container(
                            height: 40,
                            margin: const EdgeInsets.only(left: 3, right: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isHintClicked ? Palette.primary : Palette.cardBodyGrey,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lightbulb, color: Palette.brightYellow),
                                const SizedBox(width: 5),
                                bodyText(text: 'Hint', color: Colors.white, fontSize: 18),
                              ],
                            )),
                      ),
                      // spacebar
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            _keyboardProvider.setTyped(' ');
                            _keyboardProvider.addInput(' ');
                          },
                          child: Container(
                            height: 40,
                            margin: const EdgeInsets.only(left: 3, right: 3),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: typedSelector == " " ? Palette.primary : Palette.cardBodyGrey,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: bodyText(text: 'Space', color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                      // enter
                      Visibility(
                        visible: false,
                        child: InkWell(
                          onTap: () {}, //  TODO: add enter function
                          child: Container(
                            height: 40,
                            margin: const EdgeInsets.only(left: 3, right: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Palette.primary,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: bodyText(text: 'Guess', color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ]));
  }

  double calculateProgress(int level, int xp) {
    int xpNeeded = 10 * level;
    return xp / xpNeeded;
  }

  Widget _key(String letter, {double width = 40}) {
    String typedSelector = context.select((KeyboardProvider keyboardProvider) => keyboardProvider.typed);

    return InkWell(
      onTap: () {
        _keyboardProvider.setTyped(letter);
        _keyboardProvider.addInput(letter);
      },
      child: Container(
          width: width,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: typedSelector == letter ? Palette.primary : Palette.scaffold,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(child: bodyText(text: letter, color: Colors.white, fontSize: 18))),
    );
  }
}
