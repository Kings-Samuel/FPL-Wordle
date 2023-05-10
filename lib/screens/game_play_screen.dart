import 'package:flutter/material.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:fplwordle/helpers/widgets/custom_texts.dart';
import 'package:fplwordle/providers/keyboard_provider.dart';
import 'package:provider/provider.dart';

class GamePlayScreen extends StatefulWidget {
  const GamePlayScreen({Key? key}) : super(key: key);

  @override
  GamePlayScreenState createState() => GamePlayScreenState();
}

class GamePlayScreenState extends State<GamePlayScreen> {
  KeyboardProvider _keyboardProvider = KeyboardProvider();
  List<String> line1Letters = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
  List<String> line2Letters = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
  List<String> line3Letters = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

  @override
  void initState() {
    super.initState();
    _keyboardProvider = context.read<KeyboardProvider>();
    _keyboardProvider.getPlayerNames(context);
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 600;
    bool isBackspaceClicked =
        context.select((KeyboardProvider keyboardProvider) => keyboardProvider.isBackSpaceClicked);
    bool isHintClicked = context.select((KeyboardProvider keyboardProvider) => keyboardProvider.isHintClicked);
    String typedSelector = context.select((KeyboardProvider keyboardProvider) => keyboardProvider.typed);
    String input = context.select((KeyboardProvider keyboardProvider) => keyboardProvider.input);
    List<String> suggestions = context.select((KeyboardProvider keyboardProvider) => keyboardProvider.suggestions);

    return Scaffold(
        backgroundColor: Palette.scaffold,
        body: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          // keyboard
          Container(
            height: 295,
            width: isDesktop ? 500 : double.infinity,
            padding: const EdgeInsets.only(top: 10, bottom: 20),
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
                if (input.isNotEmpty)
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        String suggestion = suggestions[index];
                        return GestureDetector(
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
                        );
                      },
                    ),
                  ),
                // ** KEYBOARD ** //
                // line 1
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    line1Letters.length,
                    (index) => Expanded(
                      child: Container(
                        margin:
                            EdgeInsets.only(left: index == 0 ? 0 : 2, right: index == line1Letters.length - 1 ? 0 : 2),
                        child: _key(line1Letters[index]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // line 2
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    line2Letters.length,
                    (index) => Expanded(
                        child: Container(
                            margin: EdgeInsets.only(
                                left: index == 0 ? 0 : 2, right: index == line1Letters.length - 1 ? 0 : 2),
                            child: _key(line2Letters[index]))),
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
                    line3Letters.length,
                    (index) => Expanded(
                        child: Container(
                            margin: EdgeInsets.only(
                                left: index == 0 ? 0 : 2, right: index == line1Letters.length - 1 ? 0 : 2),
                            child: _key(line3Letters[index]))),
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
        ]));
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
