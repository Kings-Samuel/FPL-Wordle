import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/consts/routes.dart';
import 'package:fplwordle/helpers/utils/navigator.dart';
import 'package:fplwordle/providers/sound_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Widget leadingButton(BuildContext context) {
  SoundsProvider soundsProvider = context.read<SoundsProvider>();

  return IconButton(
      onPressed: () async {
        await soundsProvider.playClick();
        if (context.mounted) kIsWeb ? context.go(Routes.home) : popNavigator(context);
      },
      enableFeedback: !kIsWeb,
      icon: const Icon(Icons.arrow_back_ios, color: Colors.white));
}
