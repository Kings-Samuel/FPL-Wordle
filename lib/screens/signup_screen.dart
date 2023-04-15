import 'package:animated_neumorphic/animated_neumorphic.dart';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:fplwordle/helpers/utils/navigator.dart';
import 'package:fplwordle/helpers/widgets/custom_texts.dart';
import 'package:fplwordle/helpers/widgets/snack_bar_helper.dart';
import 'package:fplwordle/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  int _step = 1;

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _name = TextEditingController();

  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Image.asset(
                  'assets/icon.png',
                  height: 25,
                ),
                const SizedBox(width: 10),
                headingText(text: 'FPL Wordle', variation: 2, fontSize: 16)
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 20.0),
                alignment: Alignment.center,
                child: RichText(
                    text: TextSpan(
                        text: 'HAVE AN ACCOUNT?  ',
                        style: GoogleFonts.ntr(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14),
                        children: [
                      TextSpan(
                          text: 'SIGN IN',
                          style: GoogleFonts.ntr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              pushNavigator(const LoginScreen(), context);
                            })
                    ])),
              )
            ]),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/bg1.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            color: Palette.scaffold.withOpacity(0.85),
            padding: const EdgeInsets.all(30),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 180),
                  // heading
                  Align(
                      alignment: Alignment.centerLeft, child: headingText(text: 'SIGN UP', variation: 3, fontSize: 45)),
                  AnimatedContainer(
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.bounceIn,
                      child: _step == 1
                          ? Column(
                              children: [
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: bodyText(text: 'Sign up with your email address')),
                                const SizedBox(height: 20),
                                AnimatedNeumorphicContainer(
                                  depth: 0,
                                  color: const Color(0xFF1E293B),
                                  height: 50,
                                  radius: 16.0,
                                  child: TextField(
                                      controller: _email,
                                      keyboardType: TextInputType.emailAddress,
                                      style: GoogleFonts.ntr(color: Colors.white, fontSize: 16),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                                        hintText: 'example@gmail.com',
                                        hintStyle: GoogleFonts.ntr(color: Colors.grey, fontSize: 16),
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                      )),
                                ),
                              ],
                            )
                          : _step == 2
                              ? Column(
                                  children: [
                                    Align(alignment: Alignment.centerLeft, child: bodyText(text: 'Create a password')),
                                    const SizedBox(height: 20),
                                    AnimatedNeumorphicContainer(
                                      depth: 0,
                                      color: const Color(0xFF1E293B),
                                      height: 50,
                                      radius: 16.0,
                                      child: TextField(
                                          controller: _password,
                                          obscureText: _hidePassword,
                                          keyboardType: TextInputType.visiblePassword,
                                          style: GoogleFonts.ntr(color: Colors.white, fontSize: 16),
                                          decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.only(left: 15, right: 15, top: 8),
                                              hintText: '********',
                                              hintStyle: GoogleFonts.ntr(color: Colors.grey, fontSize: 16),
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              suffixIcon: IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _hidePassword = !_hidePassword;
                                                  });
                                                },
                                                icon: Icon(
                                                  _hidePassword ? Icons.visibility_off : Icons.visibility,
                                                  color: Colors.white,
                                                ),
                                              ))),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: bodyText(text: 'First name and last name')),
                                    const SizedBox(height: 20),
                                    AnimatedNeumorphicContainer(
                                      depth: 0,
                                      color: const Color(0xFF1E293B),
                                      height: 50,
                                      radius: 16.0,
                                      child: TextField(
                                          controller: _name,
                                          keyboardType: TextInputType.text,
                                          style: GoogleFonts.ntr(color: Colors.white, fontSize: 16),
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                                            hintText: 'John Doe',
                                            hintStyle: GoogleFonts.ntr(color: Colors.grey, fontSize: 16),
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                          )),
                                    ),
                                  ],
                                )),
                  const SizedBox(height: 40),
                  // buttons
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.bounceIn,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    margin: const EdgeInsets.only(right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // back button
                        if (_step > 1)
                          AnimatedNeumorphicContainer(
                              depth: 0,
                              color: Palette.primary,
                              width: 50,
                              height: 50,
                              radius: 16.0,
                              child: Center(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _step--;
                                    });
                                  },
                                  child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                                ),
                              )),
                        const Spacer(),
                        // next button
                        AnimatedNeumorphicContainer(
                            depth: 0,
                            color: Palette.primary,
                            width: _step > 1 ? 200 : MediaQuery.of(context).size.width - 150,
                            height: 50,
                            radius: 16.0,
                            child: Center(
                              child: InkWell(
                                  onTap: () {
                                    if (_step == 1) {
                                      // verify email
                                      bool isValid = EmailValidator.validate(_email.text.trim());

                                      if (isValid) {
                                        setState(() {
                                          _step++;
                                        });
                                      } else {
                                        snackBarHelper(context,
                                            message: 'Invalid email address', type: AnimatedSnackBarType.error);
                                      }
                                    } else if (_step == 2) {
                                      // verify password
                                      if (_password.text.trim().length >= 8) {
                                        setState(() {
                                          _step++;
                                        });
                                      } else {
                                        snackBarHelper(context,
                                            message: 'Password must be at least 8 characters',
                                            type: AnimatedSnackBarType.info);
                                      }
                                    } else if (_step == 3) {
                                      if (_name.text.trim().isEmpty) {
                                        snackBarHelper(context,
                                            message: 'Please enter your name', type: AnimatedSnackBarType.info);
                                      } else {
                                        // TODO: implement sign up
                                      }
                                    }
                                  },
                                  child: headingText(text: 'Continue', color: Colors.white)),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white, thickness: 1.5),
                  const SizedBox(height: 10),
                  // google login button
                  Center(
                    child: bodyText(text: 'Or sign up with', color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  AnimatedNeumorphicContainer(
                    depth: 0,
                    color: const Color(0xFF1E293B),
                    width: MediaQuery.of(context).size.width - 150,
                    height: 50,
                    radius: 16.0,
                    child: InkWell(
                      onTap: () {
                        // TODO: implement google login
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/google.png', width: 20, height: 20),
                          const SizedBox(width: 10),
                          headingText(text: 'Google', color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // privacy policy (rich text)
                  RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                          text: 'By signing up, you agree to our ',
                          style: GoogleFonts.ntr(color: Colors.white, fontSize: 16),
                          children: <TextSpan>[
                            TextSpan(
                                text: 'Terms of Service',
                                style:
                                    GoogleFonts.ntr(color: Palette.primary, fontSize: 16, fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()..onTap = () {})
                          ]))
                ],
              ),
            ),
          ),
        ));
  }
}
