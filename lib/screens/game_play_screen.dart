import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fplwordle/consts/routes.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:fplwordle/helpers/utils/navigator.dart';
import 'package:fplwordle/helpers/widgets/custom_btn.dart';
import 'package:fplwordle/helpers/widgets/custom_texts.dart';
import 'package:fplwordle/helpers/widgets/dialog_helper.dart';
import 'package:fplwordle/helpers/widgets/leading_button.dart';
import 'package:fplwordle/models/single_mode_puzzle.dart';
import 'package:fplwordle/providers/keyboard_provider.dart';
import 'package:fplwordle/screens/profile_screen.dart';
import 'package:fplwordle/screens/shop_screen.dart';
import 'package:provider/provider.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:simple_progress_indicators/simple_progress_indicators.dart';
import '../models/player.dart';
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
  bool _scaleAttrCards = false;

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
    // await secStorage.delete(key: "gameInSession"); // for testing purposes only
    // await secStorage.delete(key: "gameInSession"); // for testing purposes only

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
    _scaleAttrCards = context.select<SingleModeGameProvider, bool>((provider) => provider.scaleAttrCards);
    Player? player1 = puzzle == null ? null : Player.fromJson(jsonDecode(puzzle.player1!));
    Player? player2 = puzzle == null ? null : Player.fromJson(jsonDecode(puzzle.player2!));
    Player? player3 = puzzle == null ? null : Player.fromJson(jsonDecode(puzzle.player3!));
    Player? player4 = puzzle == null ? null : Player.fromJson(jsonDecode(puzzle.player4!));
    Player? player5 = puzzle == null ? null : Player.fromJson(jsonDecode(puzzle.player5!));
    Player? player1unveiled = puzzle == null ? null : Player.fromJson(jsonDecode(puzzle.player1unveiled!));
    Player? player2unveiled = puzzle == null ? null : Player.fromJson(jsonDecode(puzzle.player2unveiled!));
    Player? player3unveiled = puzzle == null ? null : Player.fromJson(jsonDecode(puzzle.player3unveiled!));
    Player? player4unveiled = puzzle == null ? null : Player.fromJson(jsonDecode(puzzle.player4unveiled!));
    Player? player5unveiled = puzzle == null ? null : Player.fromJson(jsonDecode(puzzle.player5unveiled!));

    // set game complete if all players are unveiled
    bool isGameCompleted = false;

    if (puzzle != null) {
      puzzle.hints = 10; // for testing purposes only
      // secStorage.write(key: "gameInSession", value: jsonEncode(puzzle.toJson()));
      isGameCompleted = player1unveiled!.isUnveiled == true &&
          player2unveiled!.isUnveiled == true &&
          player3unveiled!.isUnveiled == true &&
          player4unveiled!.isUnveiled == true &&
          player5unveiled!.isUnveiled == true;
    }

    if (isGameCompleted) {
      _gameProvider.setGameComplete();
    }

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
                                value: _calculateProgress(profile.level!, profile.xp!),
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
        // keyboard
        bottomNavigationBar: Container(
          height: 215,
          alignment: Alignment.center,
          child: Container(
            width: isDesktop ? 500 : double.infinity,
            padding:
                isDesktop ? const EdgeInsets.all(15) : const EdgeInsets.only(top: 10, bottom: 20, left: 5, right: 5),
            color: Palette.cardHeaderGrey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ** INPUT ** //
                if (input.isEmpty)
                  Center(child: bodyText(text: "Type in a Player name", color: Colors.grey, fontSize: 16))
                else
                  Center(child: bodyText(text: input, color: Colors.white, fontSize: 16)),
                // ** SUGGESTIONS ** //
                if (input.isNotEmpty && input != " ")
                  Container(
                    height: 20,
                    margin: const EdgeInsets.all(5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      // crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // previous
                        if (suggestions.isNotEmpty && _controller.hasClients)
                          Center(
                            child: InkWell(
                              onTap: () => _controller.animateTo(
                                _controller.offset - 100,
                                curve: Curves.easeOut,
                                duration: const Duration(milliseconds: 300),
                              ),
                              child: const Icon(Icons.arrow_back_ios, size: 15, color: Colors.white),
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
                            child: InkWell(
                              onTap: () => _controller.animateTo(
                                _controller.offset + 100,
                                curve: Curves.easeOut,
                                duration: const Duration(milliseconds: 300),
                              ),
                              child: const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.white),
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
                        margin:
                            EdgeInsets.only(left: index == 0 ? 0 : 2, right: index == _line1Letters.length - 1 ? 0 : 2),
                        child: _key(_line1Letters[index]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
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
                const SizedBox(height: 2),
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
                      height: 28,
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    // hint button
                    InkWell(
                      onTap: _scaleAttrCards && puzzle!.hints! <= 0
                          ? null
                          : () async {
                              _soundsProvider.playClick();
                              await _keyboardProvider.hintButtonFeedback();
                              if (mounted) {
                                await customDialog(context: context, title: "Select a trait to reveal", contentList: [
                                  SizedBox(
                                    width: 150,
                                    child: customButton(context,
                                        backgroundColor: Colors.green,
                                        icon: CupertinoIcons.arrow_right_circle,
                                        text: "Proceed", onTap: () {
                                      _gameProvider.setScaleAttrIcons(true);
                                      popNavigator(context, rootNavigator: true);
                                    }),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: 150,
                                    child: customButton(context,
                                        backgroundColor: Colors.red,
                                        icon: Icons.close,
                                        text: "Cancel",
                                        onTap: () => popNavigator(context, rootNavigator: true)),
                                  )
                                ]);
                              }
                            },
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
                    // Visibility(
                    //   visible: false,
                    //   child: InkWell(
                    //     onTap: () {}, //  todo: add enter function
                    //     child: Container(
                    //       height: 40,
                    //       margin: const EdgeInsets.only(left: 3, right: 3),
                    //       padding: const EdgeInsets.symmetric(horizontal: 5),
                    //       alignment: Alignment.center,
                    //       decoration: BoxDecoration(
                    //         color: Palette.primary,
                    //         borderRadius: BorderRadius.circular(5),
                    //       ),
                    //       child: bodyText(text: 'Guess', color: Colors.white, fontSize: 18),
                    //     ),
                    //   ),
                    // ),
                  ],
                )
              ],
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(5),
          physics: const BouncingScrollPhysics(),
          child: Column(children: [
            // heading text
            Center(
              child: bodyText(text: "Find today's Premier League Players"),
            ),
            // loading shimmer
            if (puzzle == null)
              SizedBox(
                width: isDesktop ? 550 : double.infinity,
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  Expanded(child: _shimmer(isDesktop)),
                  Expanded(child: _shimmer(isDesktop)),
                  Expanded(child: _shimmer(isDesktop)),
                  Expanded(child: _shimmer(isDesktop)),
                  Expanded(child: _shimmer(isDesktop))
                ]),
              )
            // puzzle
            else
              SizedBox(
                width: isDesktop ? 550 : double.infinity,
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  Expanded(child: _puzzleCard(player1!, player1unveiled!, puzzle.selectedAttributes!, isDesktop, 1)),
                  Expanded(child: _puzzleCard(player2!, player2unveiled!, puzzle.selectedAttributes!, isDesktop, 2)),
                  Expanded(child: _puzzleCard(player3!, player3unveiled!, puzzle.selectedAttributes!, isDesktop, 3)),
                  Expanded(child: _puzzleCard(player4!, player4unveiled!, puzzle.selectedAttributes!, isDesktop, 4)),
                  Expanded(child: _puzzleCard(player5!, player5unveiled!, puzzle.selectedAttributes!, isDesktop, 5)),
                ]),
              ),
            const SizedBox(height: 10),
          ]),
        ));
  }

  // ** WIDGETS ** //
  Widget _key(String letter, {double width = 30}) {
    String typedSelector = context.select((KeyboardProvider keyboardProvider) => keyboardProvider.typed);

    return InkWell(
      onTap: () {
        _keyboardProvider.setTyped(letter);
        _keyboardProvider.addInput(letter);
      },
      child: Container(
          width: width,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: typedSelector == letter ? Palette.primary : Palette.scaffold,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(child: bodyText(text: letter, color: Colors.white, fontSize: 18))),
    );
  }

  Widget _puzzleCard(
      Player player, Player playerUnveiled, List<String> selectedAttributes, bool isDesktop, int puzzlePosition) {
    double price = player.nowCost! / 10;
    String position = _getPosition(player.elementType!);
    final team = _getTeam(playerUnveiled.team!, position == "GK");
    String teamName = team.name.toUpperCase();
    bool isUnveiled = playerUnveiled.isUnveiled ?? false;

    String attribute1 = selectedAttributes[0];
    String attr1Value = _getAttrValue(attribute1, playerUnveiled);
    bool isAttr1Revealed = attr1Value != "0";
    String attribute2 = selectedAttributes[1];
    String attr2Value = _getAttrValue(attribute2, playerUnveiled);
    bool isAttr2Revealed = attr2Value != "0";
    String attribute3 = selectedAttributes[2];
    bool isAttr3Revealed = attr2Value != "0";
    String attr3Value = _getAttrValue(attribute3, playerUnveiled);

    // set unveiled as true if all items are  revealed
    bool isAllRevealed = isAttr1Revealed && isAttr2Revealed && isAttr3Revealed && teamName != "TEAM";
    if (isAllRevealed) {
      _gameProvider.setPlayerUnveiled(player: player, playerUnveiled: playerUnveiled, puzzlePosition: puzzlePosition);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      width: 100,
      decoration: BoxDecoration(
        color: isUnveiled ? Palette.cardBodyGreeen : Palette.cardBodyGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // price
          Container(
            height: 30,
            decoration: BoxDecoration(
              color: isUnveiled ? Palette.cardHeadGreen : Palette.cardHeaderGrey,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              ),
            ),
            child: Center(
              child: bodyText(text: "£$price", color: Colors.white, fontSize: 18),
            ),
          ),
          const SizedBox(height: 5),
          // team shirt
          if (teamName == "TEAM" && _scaleAttrCards)
            InkWell(
              onTap: () async {
                await _gameProvider.useHint(
                    player: player, playerUnveiled: playerUnveiled, puzzlePosition: puzzlePosition);
                setState(() {});
              },
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    height: 40,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                      image: AssetImage(team.shirtAsset),
                    )),
                  ).animate(onComplete: (controller) => controller.repeat(min: 0.85, max: 1.0, period: 800.ms)).scale(
                        delay: Duration.zero,
                        duration: 800.ms,
                      ),
                  const SizedBox(height: 5),
                  // name
                  FittedBox(
                    child: bodyText(
                        text: teamName,
                        color: teamName == "TEAM" ? Colors.grey : Colors.white,
                        fontSize: isDesktop ? 14 : 12),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                // shirt
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  height: 40,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                    image: AssetImage(team.shirtAsset),
                  )),
                ),
                const SizedBox(height: 5),
                // name
                FittedBox(
                  child: bodyText(
                      text: teamName,
                      color: teamName == "TEAM" ? Colors.grey : Colors.white,
                      fontSize: isDesktop ? 14 : 12),
                ),
              ],
            ),
          const SizedBox(height: 5),
          // attributes
          _attrCard(attribute1, attr1Value, isAttr1Revealed, isDesktop, player, playerUnveiled, puzzlePosition),
          const SizedBox(height: 5),
          _attrCard(attribute2, attr2Value, isAttr2Revealed, isDesktop, player, playerUnveiled, puzzlePosition),
          const SizedBox(height: 5),
          _attrCard(attribute3, attr3Value, isAttr3Revealed, isDesktop, player, playerUnveiled, puzzlePosition),
          const SizedBox(height: 5),
          // position
          Container(
            height: 30,
            decoration: BoxDecoration(
              color: isUnveiled ? Palette.cardHeadGreen : Palette.cardHeaderGrey,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10.0),
                bottomRight: Radius.circular(10.0),
              ),
            ),
            child: Center(
              child: bodyText(text: position, color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    ).animate().scale();
  }

  Widget _shimmer(bool isDesktop) {
    return Container(
      height: isDesktop ? 350 : 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Shimmer(
        color: Palette.primary,
        direction: const ShimmerDirection.fromLTRB(),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          width: 100,
          height: isDesktop ? 350 : 400,
          decoration: BoxDecoration(
            color: Palette.cardBodyGrey,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _attrCard(String attribute, String value, bool isRevealed, bool isDesktop, Player player,
      Player playerUnveiled, int puzzlePosition) {
    final details = _getAttrDetails(attribute);

    if (_scaleAttrCards && !isRevealed) {
      return InkWell(
        onTap: () async {
          await _gameProvider.useHint(
              player: player, playerUnveiled: playerUnveiled, puzzlePosition: puzzlePosition, attribute: attribute);
          setState(() {});
        },
        child: Column(children: [
          // icon image
          Badge(
            backgroundColor: Palette.primary,
            isLabelVisible: isRevealed,
            label: Center(child: bodyText(text: value, textAlign: TextAlign.center, fontSize: 14)),
            child: Image.asset(details.asset, height: 40, width: 40, color: isRevealed ? null : Colors.grey),
          ).animate(onComplete: (controller) => controller.repeat(min: 0.85, max: 1.0, period: 800.ms)).scale(
                delay: Duration.zero,
                duration: 800.ms,
              ),
          const SizedBox(height: 3),
          FittedBox(
              child: bodyText(
                  text: details.name,
                  color: isRevealed ? Colors.white : Colors.grey,
                  fontSize: isDesktop ? 14 : 12,
                  textAlign: TextAlign.center)),
        ]),
      );
    } else {
      return Column(children: [
        // icon image
        Badge(
          backgroundColor: Palette.primary,
          isLabelVisible: isRevealed,
          label: Center(child: bodyText(text: value, textAlign: TextAlign.center, fontSize: 14)),
          child: Image.asset(details.asset, height: 40, width: 40, color: isRevealed ? null : Colors.grey),
        ),
        const SizedBox(height: 3),
        FittedBox(
            child: bodyText(
                text: details.name,
                color: isRevealed ? Colors.white : Colors.grey,
                fontSize: isDesktop ? 14 : 12,
                textAlign: TextAlign.center)),
      ]);
    }
  }

  // ** SWITCH CASES && FUNCTIONS** //
  ({String name, String asset}) _getAttrDetails(String attribute) {
    switch (attribute) {
      case "totalPoints":
        return (name: "Total Points", asset: "attrIcons/totalPoints.png");
      case "bonus":
        return (name: "Bonus", asset: "attrIcons/bonus.png");
      case "goalsScored":
        return (name: "Goals Scored", asset: "attrIcons/goalsScored.png");
      case "assists":
        return (name: "Assists", asset: "attrIcons/assists.png");
      case "cleanSheets":
        return (name: "Clean Sheets", asset: "attrIcons/cleanSheets.png");
      case "goalsConceded":
        return (name: "Goals Conceded", asset: "attrIcons/goalsConceded.png");
      case "ownGoals":
        return (name: "Own Goals", asset: "attrIcons/ownGoals.png");
      case "penaltiesMissed":
        return (name: "Penalties Missed", asset: "attrIcons/penaltiesMissed.png");
      case "yellowCards":
        return (name: "Yellow Cards", asset: "attrIcons/yellowCards.png");
      case "redCards":
        return (name: "Red Cards", asset: "attrIcons/redCards.png");
      case "starts":
        return (name: "Starts", asset: "attrIcons/starts.png");
      case "pointsPerGame":
        return (name: "Points Per Game", asset: "attrIcons/pointsPerGame.png");
      default:
        return (name: "Total Points", asset: "attrIcons/totalPoints.png");
    }
  }

  ({String name, String shirtAsset}) _getTeam(int teamNo, bool isGk) {
    switch (teamNo) {
      case 1:
        return (name: "Arsenal", shirtAsset: isGk ? "assets/shirts/shirt_1_1.png" : "assets/shirts/shirt_1.png");
      case 2:
        return (name: "A. Villa", shirtAsset: isGk ? "assets/shirts/shirt_2_1.png" : "assets/shirts/shirt_2.png");
      case 3:
        return (name: "Bournemouth", shirtAsset: isGk ? "assets/shirts/shirt_3_1.png" : "assets/shirts/shirt_3.png");
      case 4:
        return (name: "Brentford", shirtAsset: isGk ? "assets/shirts/shirt_4_1.png" : "assets/shirts/shirt_4.png");
      case 5:
        return (name: "Brighton", shirtAsset: isGk ? "assets/shirts/shirt_5_1.png" : "assets/shirts/shirt_5.png");
      case 6:
        return (name: "Chelsea", shirtAsset: isGk ? "assets/shirts/shirt_6_1.png" : "assets/shirts/shirt_6.png");
      case 7:
        return (name: "Crystal Palace", shirtAsset: isGk ? "assets/shirts/shirt_7_1.png" : "assets/shirts/shirt_7.png");
      case 8:
        return (name: "Everton", shirtAsset: isGk ? "assets/shirts/shirt_8_1.png" : "assets/shirts/shirt_8.png");
      case 9:
        return (name: "Fulham", shirtAsset: isGk ? "assets/shirts/shirt_9_1.png" : "assets/shirts/shirt_9.png");
      case 10:
        return (name: "Leicester", shirtAsset: isGk ? "assets/shirts/shirt_10_1.png" : "assets/shirts/shirt_10.png");
      case 11:
        return (name: "Leeds", shirtAsset: isGk ? "assets/shirts/shirt_11_1.png" : "assets/shirts/shirt_11.png");
      case 12:
        return (name: "Liverpool", shirtAsset: isGk ? "assets/shirts/shirt_12_1.png" : "assets/shirts/shirt_12.png");
      case 13:
        return (name: "Man City", shirtAsset: isGk ? "assets/shirts/shirt_13_1.png" : "assets/shirts/shirt_13.png");
      case 14:
        return (name: "Man Utd", shirtAsset: isGk ? "assets/shirts/shirt_14_1.png" : "assets/shirts/shirt_14.png");
      case 15:
        return (name: "Newcastle", shirtAsset: isGk ? "assets/shirts/shirt_15_1.png" : "assets/shirts/shirt_15.png");
      case 16:
        return (name: "Nott Forest", shirtAsset: isGk ? "assets/shirts/shirt_16_1.png" : "assets/shirts/shirt_16.png");
      case 17:
        return (name: "Southampton", shirtAsset: isGk ? "assets/shirts/shirt_17_1.png" : "assets/shirts/shirt_17.png");
      case 18:
        return (name: "Tottenham", shirtAsset: isGk ? "assets/shirts/shirt_18_1.png" : "assets/shirts/shirt_18.png");
      case 19:
        return (name: "West Ham", shirtAsset: isGk ? "assets/shirts/shirt_19_1.png" : "assets/shirts/shirt_19.png");
      case 20:
        return (name: "Wolves", shirtAsset: isGk ? "assets/shirts/shirt_20_1.png" : "assets/shirts/shirt_20.png");
      default:
        return (name: "Team", shirtAsset: "assets/shirts/shirt_0.png");
    }
  }

  String _getPosition(int positionNo) {
    switch (positionNo) {
      case 1:
        return "GK";
      case 2:
        return "DEF";
      case 3:
        return "MID";
      case 4:
        return "FWD";
      default:
        return "";
    }
  }

  double _calculateProgress(int level, int xp) {
    int xpNeeded = 10 * level;
    return xp / xpNeeded;
  }

  String _getAttrValue(String attribute, Player playerUnveiled) {
    switch (attribute) {
      case "totalPoints":
        return playerUnveiled.totalPoints.toString();
      case "bonus":
        return playerUnveiled.bonus.toString();
      case "goalsScored":
        return playerUnveiled.goalsScored.toString();
      case "assists":
        return playerUnveiled.assists.toString();
      case "cleanSheets":
        return playerUnveiled.cleanSheets.toString();
      case "goalsConceded":
        return playerUnveiled.goalsConceded.toString();
      case "ownGoals":
        return playerUnveiled.ownGoals.toString();
      case "penaltiesMissed":
        return playerUnveiled.penaltiesMissed.toString();
      case "yellowCards":
        return playerUnveiled.yellowCards.toString();
      case "redCards":
        return playerUnveiled.redCards.toString();
      case "starts":
        return playerUnveiled.starts.toString();
      case "pointsPerGame":
        return playerUnveiled.pointsPerGame.toString();
      default:
        return playerUnveiled.totalPoints.toString();
    }
  }
}
