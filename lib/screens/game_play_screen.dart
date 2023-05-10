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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.scaffold,
      // keyboard
      bottomNavigationBar: Container(
        height: 200,
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: Palette.cardHeaderGrey,
        alignment: Alignment.center,
        child: Column(
          children: [
            // line 1
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                line1Letters.length,
                (index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: index == 0 ? 0 : 2, right: index == line1Letters.length - 1 ? 0 : 2),
                    child: _key(line1Letters[index]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // line 2
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                line2Letters.length,
                (index) => _key(line2Letters[index]),
              ),
            ),
            const SizedBox(height: 10),
            // line 3
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                line3Letters.length,
                (index) => _key(line3Letters[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _key(String letter) {
    return InkWell(
      onTap: () {
        print(letter);
      },
      splashColor: Palette.primary,
      child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Palette.scaffold,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(child: bodyText(text: letter, color: Colors.white, fontSize: 18))),
    );
  }
}
