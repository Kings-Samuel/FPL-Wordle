import 'dart:convert';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../helpers/utils/init_sec_storage.dart';
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
  final confettiController = ConfettiController(duration: const Duration(seconds: 1));
  final FocusNode _kBFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _keyboardProvider = context.read<KeyboardProvider>();
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
      await _gameProvider.loadGameInSession(context);
    } else {
      await _gameProvider.loadNewGame(context);
    }

    _keyboardProvider.getPlayerNames(_gameProvider.players);
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
      isGameCompleted = player1unveiled!.isUnveiled == true &&
          player2unveiled!.isUnveiled == true &&
          player3unveiled!.isUnveiled == true &&
          player4unveiled!.isUnveiled == true &&
          player5unveiled!.isUnveiled == true &&
          puzzle.isFinished != true;
    }

    if (isGameCompleted) {
      _gameProvider.setGameComplete(context, shouldNotifyListeners: true);
    }

    if (puzzle?.isFinished == true) {
      confettiController.play();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        RawKeyboardListener(
          autofocus: true,
          focusNode: _kBFocusNode,
          onKey: (RawKeyEvent event) async {
            if (event is RawKeyDownEvent) {
              String key = event.data.logicalKey.keyLabel.toUpperCase();

              if (key.isNotEmpty && key.length == 1 && key != " ") {
                _keyboardProvider.setTyped(key);
                _keyboardProvider.addInput(key);
              }

              if (event.logicalKey == LogicalKeyboardKey.backspace) {
                if (input.isNotEmpty) {
                  _keyboardProvider.backSpace();
                }
              }

              if (event.logicalKey == LogicalKeyboardKey.enter) {
                if (input.isNotEmpty) {
                  _gameProvider.guessPlayer(context, input);
                  _keyboardProvider.clearInput();
                  // implement gameover
                  if (puzzle!.lives! <= 0 && mounted) {
                    _gameProvider.setGameOver(context);
                  }
                }
              }

              if (event.logicalKey == LogicalKeyboardKey.space) {
                if (input.isNotEmpty) {
                  _keyboardProvider.setTyped(' ');
                  _keyboardProvider.addInput(' ');
                }
              }
            }
          },
          child: Scaffold(
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
                                    child: RandomAvatar(_user!.name!,
                                        height: 40, width: 40, allowDrawingOutsideViewBox: true),
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
              // game complete dialog
              bottomNavigationBar: puzzle?.isFinished == true
                  ? Container(
                      height: 225,
                      padding: const EdgeInsets.all(10),
                      child: Column(children: [
                        // heading
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.check, color: Colors.green),
                          const SizedBox(width: 5),
                          bodyText(
                              text: "Hurray! You've completed the puzzle",
                              color: Colors.white,
                              fontSize: 16,
                              bold: true),
                        ]),
                        const SizedBox(height: 10),
                        // share and view achievements btns
                        SizedBox(
                          width: isDesktop ? 500 : double.infinity,
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Expanded(
                              child: SizedBox(
                                  height: 40,
                                  width: 150,
                                  child: customButton(
                                    context,
                                    icon: Icons.ios_share,
                                    text: "Share Score",
                                    onTap: () {},
                                  )),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: SizedBox(
                                  height: 40,
                                  width: 150,
                                  child: customButton(
                                    context,
                                    icon: CommunityMaterialIcons.trophy_award,
                                    text: "View Achievements",
                                    onTap: () {},
                                  )),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 10),
                        // scores
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _scoreCard("Games Completed", 1),
                          const SizedBox(width: 5),
                          _scoreCard("Players Found", 5),
                          const SizedBox(width: 5),
                          _scoreCard("Win Streak", 1),
                          const SizedBox(width: 5),
                          _scoreCard("Longest Win Streak", 1),
                        ]),
                        const SizedBox(height: 10),
                        // play again btn
                        Shimmer(
                          color: Colors.white,
                          colorOpacity: 0.45,
                          child: SizedBox(
                            width: isDesktop ? 500 : double.infinity,
                            child: SizedBox(
                                height: 40,
                                width: 150,
                                child: customButton(context,
                                    backgroundColor: Colors.green,
                                    icon: Icons.replay,
                                    text: "Play Again",
                                    onTap: () {})),
                          ),
                        ),
                      ]))
                  // keyboard
                  : Container(
                      height: input.isEmpty ? 215 : 225,
                      alignment: Alignment.center,
                      child: Container(
                        width: isDesktop ? 500 : double.infinity,
                        padding: isDesktop
                            ? const EdgeInsets.all(15)
                            : const EdgeInsets.only(top: 10, bottom: 20, left: 5, right: 5),
                        color: Palette.cardHeaderGrey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // ** INPUT ** //
                            if (input.isEmpty)
                              Column(
                                children: [
                                  bodyText(text: "Type in a Player name", color: Colors.grey, fontSize: 16),
                                  const SizedBox(height: 10),
                                ],
                              )
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
                                                onTap: () async {
                                                  _keyboardProvider.useSuggestion(suggestion);
                                                  _gameProvider.guessPlayer(context, suggestion);
                                                  // implement gameover
                                                  if (puzzle!.lives! <= 0 && mounted) {
                                                    _gameProvider.setGameOver(context);
                                                  }
                                                },
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
                                    margin: EdgeInsets.only(
                                        left: index == 0 ? 0 : 2, right: index == _line1Letters.length - 1 ? 0 : 2),
                                    child: _key(_line1Letters[index], puzzle),
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
                                        child: _key(_line2Letters[index], puzzle))),
                              ),
                            ),
                            const SizedBox(height: 5),
                            // line 3
                            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                              _key("-", puzzle, width: 25),
                              const SizedBox(width: 2),
                              _key("'", puzzle, width: 25),
                              const SizedBox(width: 2),
                              ...List.generate(
                                _line3Letters.length,
                                (index) => Expanded(
                                    child: Container(
                                        margin: EdgeInsets.only(
                                            left: index == 0 ? 0 : 2, right: index == _line1Letters.length - 1 ? 0 : 2),
                                        child: _key(_line3Letters[index], puzzle))),
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
                            const SizedBox(height: 5),
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
                                            await customDialog(
                                                context: context,
                                                title: "Select a trait to reveal",
                                                contentList: [
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
                padding: const EdgeInsets.symmetric(horizontal: 10),
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
                    Selector<SingleModeGameProvider, int>(
                      selector: (_, provider) => provider.lastUpdateTime,
                      builder: (context, lastUpdateTime, child) {
                        return SizedBox(
                          width: isDesktop ? 550 : double.infinity,
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                            Expanded(
                                child:
                                    _puzzleCard(player1!, player1unveiled!, puzzle.selectedAttributes!, isDesktop, 1)),
                            Expanded(
                                child:
                                    _puzzleCard(player2!, player2unveiled!, puzzle.selectedAttributes!, isDesktop, 2)),
                            Expanded(
                                child:
                                    _puzzleCard(player3!, player3unveiled!, puzzle.selectedAttributes!, isDesktop, 3)),
                            Expanded(
                                child:
                                    _puzzleCard(player4!, player4unveiled!, puzzle.selectedAttributes!, isDesktop, 4)),
                            Expanded(
                                child:
                                    _puzzleCard(player5!, player5unveiled!, puzzle.selectedAttributes!, isDesktop, 5)),
                          ]),
                        );
                      },
                    ),
                  //! for testing purposes only - clear game in session btn
                  if (kDebugMode)
                    Column(
                      children: [
                        const SizedBox(height: 40),
                        SizedBox(
                          width: 300,
                          child: customButton(context,
                              backgroundColor: Colors.red,
                              icon: Icons.close,
                              text: "Clear Game In Session", onTap: () async {
                            await secStorage.delete(key: "gameInSession");
                            await secStorage.delete(key: "lastGameId");
                          }),
                        ),
                      ],
                    )
                ]),
              )),
        ),
        // confetti
        ConfettiWidget(
          confettiController: confettiController,
          shouldLoop: true,
          blastDirectionality: BlastDirectionality.explosive,
        )
      ],
    );
  }

  // ** WIDGETS ** //
  Widget _key(String letter, SingleModePuzzle? puzzle, {double width = 30}) {
    String typedSelector = context.select((KeyboardProvider keyboardProvider) => keyboardProvider.typed);

    return InkWell(
      onTap: puzzle == null
          ? null
          : () {
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
    final team = _gameProvider.getTeam(playerUnveiled.team ?? 0, position == "GK");
    String teamName = team.name.toUpperCase();
    bool isUnveiled = playerUnveiled.isUnveiled ?? false;

    String attribute1 = selectedAttributes[0];
    String attr1Value = _getAttrValue(attribute1, playerUnveiled);
    bool isAttr1Revealed = attr1Value != "null";
    String attribute2 = selectedAttributes[1];
    String attr2Value = _getAttrValue(attribute2, playerUnveiled);
    bool isAttr2Revealed = attr2Value != "null";
    String attribute3 = selectedAttributes[2];
    String attr3Value = _getAttrValue(attribute3, playerUnveiled);
    bool isAttr3Revealed = attr3Value != "null";

    // set unveiled as true if all items are  revealed
    bool isAllRevealed = isAttr1Revealed && isAttr2Revealed && isAttr3Revealed && teamName != "TEAM";
    if (isAllRevealed && !isUnveiled) {
      _gameProvider.setPlayerUnveiled(context,
          player: player, playerUnveiled: playerUnveiled, puzzlePosition: puzzlePosition);
      _keyboardProvider.removePlayerName("${player.firstName} ${player.secondName}");
    }

    return Selector<SingleModeGameProvider, int>(
        selector: (_, provider) => provider.puzzleCardToAnimate,
        builder: (context, puzzleCardToAnimate, child) {
          if (puzzleCardToAnimate == puzzlePosition) {
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
                  // name
                  if (isAllRevealed)
                    Column(children: [
                      const SizedBox(height: 3),
                      Center(
                        child: bodyText(
                            text: player.webName!.toUpperCase(), color: Colors.white, fontSize: isDesktop ? 14 : 12),
                      ),
                      const SizedBox(height: 3),
                      // Center(
                      //   child: bodyText(
                      //       text: player.secondName!.toUpperCase(), color: Colors.white, fontSize: isDesktop ? 14 : 12),
                      // ),
                      // const SizedBox(height: 3),
                    ]),
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
                        await Future.delayed(const Duration(milliseconds: 500), () {
                          setState(() {});
                        });
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
                          )
                              .animate(
                                  onComplete: (controller) => controller.repeat(min: 0.85, max: 1.0, period: 800.ms))
                              .scale(
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
            ).animate(onComplete: (controller) => controller.repeat(min: 0.95, max: 1.0, period: 800.ms)).scale(
                  delay: Duration.zero,
                  duration: 800.ms,
                );
          } else {
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
                  // name
                  if (isAllRevealed)
                    Column(children: [
                      const SizedBox(height: 3),
                      Center(
                        child: bodyText(
                            text: player.webName!.toUpperCase(), color: Colors.white, fontSize: isDesktop ? 14 : 12),
                      ),
                      const SizedBox(height: 3),
                      // Center(
                      //   child: bodyText(
                      //       text: player.secondName!.toUpperCase(), color: Colors.white, fontSize: isDesktop ? 14 : 12),
                      // ),
                      // const SizedBox(height: 3),
                    ]),
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
                        await Future.delayed(const Duration(milliseconds: 500), () {
                          setState(() {});
                        });
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
                          )
                              .animate(
                                  onComplete: (controller) => controller.repeat(min: 0.95, max: 1.0, period: 800.ms))
                              .scale(
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
            ).animate(onPlay: (controller) => controller.forward(from: 0.95)).scale();
          }
        });
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
          await Future.delayed(const Duration(milliseconds: 500), () {
            setState(() {});
          });
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
          // name
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
          child: isRevealed
              ? Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(details.asset),
                    ),
                  ),
                )
              : ImageIcon(
                  AssetImage(details.asset),
                  size: 40,
                  color: Colors.grey,
                ),
        ),
        const SizedBox(height: 3),
        // name
        FittedBox(
            child: bodyText(
                text: details.name,
                color: isRevealed ? Colors.white : Colors.grey,
                fontSize: isDesktop ? 14 : 12,
                textAlign: TextAlign.center)),
      ]);
    }
  }

  Widget _scoreCard(String title, int value) {
    return Column(
      children: [
        headingText(text: value.toString(), fontSize: 18),
        const SizedBox(height: 5),
        bodyText(text: title, fontSize: 14, color: Colors.grey),
      ],
    );
  }

  // ** SWITCH CASES && FUNCTIONS** //
  ({String name, String asset}) _getAttrDetails(String attribute) {
    switch (attribute) {
      case "totalPoints":
        return (name: "Total Points", asset: "assets/attrIcons/totalPoints.png");
      case "bonus":
        return (name: "Bonus", asset: "assets/attrIcons/bonus.png");
      case "goalsScored":
        return (name: "Goals Scored", asset: "assets/attrIcons/goalsScored.png");
      case "assists":
        return (name: "Assists", asset: "assets/attrIcons/assists.png");
      case "cleanSheets":
        return (name: "Clean Sheets", asset: "assets/attrIcons/cleanSheets.png");
      case "goalsConceded":
        return (name: "Goals Conceded", asset: "assets/attrIcons/goalsConceded.png");
      case "ownGoals":
        return (name: "Own Goals", asset: "assets/attrIcons/ownGoals.png");
      case "penaltiesMissed":
        return (name: "Penalties Missed", asset: "assets/attrIcons/penaltiesMissed.png");
      case "yellowCards":
        return (name: "Yellow Cards", asset: "assets/attrIcons/yellowCards.png");
      case "redCards":
        return (name: "Red Cards", asset: "assets/attrIcons/redCards.png");
      case "starts":
        return (name: "Starts", asset: "assets/attrIcons/starts.png");
      case "pointsPerGame":
        return (name: "Points Per Game", asset: "assets/attrIcons/pointsPerGame.png");
      default:
        return (name: "Total Points", asset: "assets/attrIcons/totalPoints.png");
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
