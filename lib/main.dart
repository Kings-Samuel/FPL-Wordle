import 'package:connection_notifier/connection_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:fplwordle/helpers/utils/navigator.dart';
import 'package:fplwordle/helpers/widgets/loading_animation.dart';
import 'package:fplwordle/models/user.dart';
import 'package:fplwordle/providers.dart';
import 'package:fplwordle/providers/auth_provider.dart';
import 'package:fplwordle/screens/email_verification_screen.dart';
import 'package:fplwordle/screens/onboarding_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ms_material_color/ms_material_color.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'helpers/utils/init_appwrite.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  setPathUrlStrategy();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initAppwrite();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return materialApp();
    } else {
      return ConnectionNotifier(
          disconnectedContent: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  '😣 You are currently offline',
                  style: GoogleFonts.ntr(color: Colors.white, fontSize: 12, fontWeight: FontWeight.normal),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                alignment: Alignment.center,
                height: 20,
                width: 20,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            ],
          ),
          connectedContent: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '😃 Back Online',
                style: GoogleFonts.ntr(color: Colors.white, fontSize: 12, fontWeight: FontWeight.normal),
                textAlign: TextAlign.center,
              ),
              const SizedBox(width: 5),
              const Icon(Icons.check, color: Colors.white)
            ],
          ),
          child: materialApp());
    }
  }

  Widget materialApp() {
    return MultiProvider(
      providers: providers,
      child: MaterialApp(
        title: 'Fantasy Football Guesser',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: MsMaterialColor(Palette.primary.value),
          primaryColor: Colors.white,
          appBarTheme: const AppBarTheme(
            iconTheme: IconThemeData(color: Palette.cardHeaderGrey),
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: Palette.scaffold,
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: MaterialStateProperty.all(Colors.grey),
          ),
          textTheme: kIsWeb
              ? null
              : GoogleFonts.ntrTextTheme(
                  Theme.of(context).textTheme,
                ),
        ),
        home: const AuthFlow(),
      ).animate().fadeIn(duration: const Duration(milliseconds: 400)),
    );
  }
}

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  @override
  void initState() {
    super.initState();
    authflow();
  }

  Future<void> authflow() async {
    AuthProvider authProvider = context.read<AuthProvider>();

    // check if onboarding is complete
    bool onboardingComplete = await authProvider.isOnboardingComplete();

    if (onboardingComplete && mounted) {
      // check if user is logged in
      bool isLoggedIn = await authProvider.isLoggedIn();

      if (isLoggedIn && mounted) {
        // check if user is verified
        User user = authProvider.user!;
        bool isVerified = user.emailVerification!;

        if (isVerified) {
          FlutterNativeSplash.remove();
          transitioner(const HomeScreen(), context, replacement: true);
        } else {
          FlutterNativeSplash.remove();
          transitioner(
              EmailVerificationScreen(
                email: user.email!,
                name: user.name!,
              ),
              context,
              replacement: true);
        }
      } else {
        FlutterNativeSplash.remove();
        transitioner(const HomeScreen(), context, replacement: true);
      }
    } else {
      if (!kIsWeb)  FlutterNativeSplash.remove();
      transitioner(const OnboardingScreen(), context, replacement: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: loadingAnimation(),
    ));
  }
}
