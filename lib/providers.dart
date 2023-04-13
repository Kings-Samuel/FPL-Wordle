import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'providers/auth_provider.dart';

List<SingleChildWidget> providers = [
  ChangeNotifierProvider(create: (_) => AuthProvider()),
];
