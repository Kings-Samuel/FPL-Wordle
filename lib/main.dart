import 'package:connection_notifier/connection_notifier.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/helpers/utils/color_palette.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ms_material_color/ms_material_color.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'helpers/utils/init_appwrite.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await initAppwrite();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: ConnectionNotifier(
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
        child: MaterialApp(
          title: 'FPL Wordle',
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
            textTheme: GoogleFonts.ntrTextTheme(
              Theme.of(context).textTheme,
            ),
          ),
        ),
      ),
    );
  }
}


// TODO: display splash screen while waiting for data to load