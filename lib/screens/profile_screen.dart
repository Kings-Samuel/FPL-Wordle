import 'package:animated_neumorphic/animated_neumorphic.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:fplwordle/helpers/utils/navigator.dart';
import 'package:fplwordle/helpers/widgets/custom_texts.dart';
import 'package:fplwordle/models/user.dart';
import 'package:fplwordle/providers/auth_provider.dart';
import 'package:fplwordle/screens/signin_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:random_avatar/random_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = context.read<AuthProvider>();
    User? user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            child: InkWell(
              onTap: () {
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
                        bodyText(text: '14', color: Colors.white, fontSize: 20, bold: true), //TODO: implement coins
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
          )
        ],
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // profile info
              if (user == null)
                RichText(
                    text: TextSpan(
                        text: 'You are not signed in \n',
                        style: GoogleFonts.ntr(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14),
                        children: [
                      TextSpan(
                          text: 'Sign in to sync your progress and access many more features',
                          style: GoogleFonts.ntr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              transitioner(const SignInScreen(), context);
                            })
                    ]))
              else
                Column(
                  children: [
                    Center(
                      child: RandomAvatar(user.name!, height: 100, width: 100, allowDrawingOutsideViewBox: true),
                    ),
                    const SizedBox(height: 10),
                    bodyText(text: user.name!, fontSize: 20, bold: true),
                    bodyText(text: user.email!),
                  ],
                ),
              const SizedBox(height: 20),
              //
            ],
          )),
    );
  }
}
