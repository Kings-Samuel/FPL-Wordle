import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/keyboard_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/sound_provider.dart';

List<SingleChildWidget> providers = [
  ChangeNotifierProvider(create: (_) => AuthProvider()),
  ChangeNotifierProvider(create: (_) => GameProvider()),
  ChangeNotifierProvider(create: (_) => ProfileProvider()),
  ChangeNotifierProvider(create: (_) => SoundsProvider()),
  ChangeNotifierProvider(create: (_) => KeyboardProvider()),
];
