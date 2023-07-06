import 'package:fplwordle/providers/misc_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'providers/auth_provider.dart';
import 'providers/single_mode_game_provider.dart';
import 'providers/keyboard_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/sound_provider.dart';

List<SingleChildWidget> providers = [
  ChangeNotifierProvider(create: (_) => AuthProvider()),
  ChangeNotifierProvider(create: (_) => SingleModeGameProvider()),
  ChangeNotifierProvider(create: (_) => ProfileProvider()),
  ChangeNotifierProvider(create: (_) => SoundsProvider()),
  ChangeNotifierProvider(create: (_) => KeyboardProvider()),
  ChangeNotifierProvider(create: (_) => MiscProvider()),
];