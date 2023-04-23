import 'package:animated_neumorphic/animated_neumorphic.dart';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:fplwordle/helpers/utils/navigator.dart';
import 'package:fplwordle/helpers/widgets/custom_texts.dart';
import 'package:fplwordle/helpers/widgets/snack_bar_helper.dart';
import 'package:fplwordle/main.dart';
import 'package:fplwordle/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../helpers/widgets/loading_animation.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String name;
  const EmailVerificationScreen({Key? key, required this.email, required this.name}) : super(key: key);

  @override
  EmailVerificationScreenState createState() => EmailVerificationScreenState();
}

class EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = false;
  late Future<String?> _future;
  AuthProvider _authProvider = AuthProvider();
  String otpInput = '';

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _future = _authProvider.sendOTP(email: widget.email, name: widget.name);
  }

  @override
  Widget build(BuildContext context) {
    int otpResendCountdownSelector = context.select<AuthProvider, int>((provider) => provider.otpResendCountdown);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // email lottie animation
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 40),
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: AssetImage('assets/email-verification.gif'),
                  ),
                ),
              ),
            ),
            // email verification text
            Center(
              child: headingText(text: 'Email Verification', fontSize: 24),
            ),
            Center(
              child:
                  bodyText(text: 'Enter the code sent to ${widget.email}', textAlign: TextAlign.center, fontSize: 16),
            ),
            const SizedBox(height: 20),

            FutureBuilder(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: loadingAnimation(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: bodyText(text: snapshot.error.toString(), fontSize: 16),
                  );
                }

                String? sentOTP = snapshot.data;

                if (sentOTP == null) {
                  return Center(
                    child: bodyText(text: 'Error sending OTP. ${_authProvider.error}', fontSize: 16),
                  );
                } else {
                  return Column(
                    children: [
                      // code input field
                      Container(
                        alignment: Alignment.center,
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: PinCodeTextField(
                          appContext: context,
                          length: 6,
                          obscureText: false,
                          animationType: AnimationType.fade,
                          pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(5),
                              fieldHeight: 50,
                              fieldWidth: 40,
                              activeFillColor: Colors.white,
                              inactiveFillColor: Colors.white,
                              inactiveColor: Palette.primary),
                          animationDuration: const Duration(milliseconds: 300),
                          enableActiveFill: true,
                          onChanged: (value) {
                            setState(() {
                              otpInput = value;
                            });
                          },
                          beforeTextPaste: (text) {
                            return true;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // resend code button
                      RichText(
                          text: TextSpan(children: [
                        TextSpan(
                            text: 'Didn\'t receive the code? ',
                            style: GoogleFonts.ntr(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        TextSpan(
                            text: 'Resend',
                            style: GoogleFonts.ntr(
                                color: otpResendCountdownSelector == 0 ? Palette.primary : Palette.scaffold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                if (otpResendCountdownSelector == 0) {
                                  _future = _authProvider.sendOTP(email: widget.email, name: widget.name);
                                  snackBarHelper(context, message: 'OTP resent', type: AnimatedSnackBarType.success);
                                  setState(() {});
                                }
                              }),
                      ])),
                      const SizedBox(height: 20),
                      // verify button
                      InkWell(
                        onTap: _isLoading
                            ? null
                            : () async {
                                setState(() {
                                  _isLoading = true;
                                });

                                // verify otp
                                await _authProvider.verifyOTP(otpInput).then((succes) async {
                                  if (succes) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    // verify email account
                                    await _authProvider.verifyEmail().then((success) {
                                      if (success) {
                                        pushAndRemoveNavigator(const MyApp(), context);
                                      } else {
                                        snackBarHelper(context,
                                            message: _authProvider.error, type: AnimatedSnackBarType.error);
                                      }
                                    });
                                  } else {
                                    snackBarHelper(context,
                                        message: _authProvider.error, type: AnimatedSnackBarType.error);
                                  }
                                  setState(() {
                                    _isLoading = false;
                                  });
                                });
                              },
                        child: AnimatedNeumorphicContainer(
                            depth: 0,
                            color: Palette.primary,
                            width: MediaQuery.of(context).size.width > 600 ? 400 : MediaQuery.of(context).size.width,
                            height: 50,
                            radius: 16.0,
                            child: _isLoading
                                ? loadingAnimation()
                                : Center(
                                    child: headingText(text: 'Verify', color: Colors.white),
                                  )),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
