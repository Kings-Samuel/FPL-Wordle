import 'package:flutter/material.dart';
import 'package:fplwordle/providers/sound_provider.dart';
import 'package:provider/provider.dart';

Widget leadingButton(BuildContext context) {
  SoundsProvider soundsProvider = context.read<SoundsProvider>();

  return IconButton(
      onPressed: () async {
        await soundsProvider.playClick();
        if (context.mounted) Navigator.pop(context);
      },
      icon: const Icon(Icons.arrow_back_ios, color: Colors.white));
}
