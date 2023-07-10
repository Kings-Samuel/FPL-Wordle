import 'package:animated_neumorphic/animated_neumorphic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/helpers/widgets/custom_btn.dart';
import 'package:fplwordle/helpers/widgets/custom_texts.dart';
import 'package:fplwordle/helpers/widgets/leading_button.dart';
import 'package:fplwordle/helpers/widgets/snack_bar_helper.dart';
import 'package:fplwordle/providers/profile_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../helpers/utils/color_palette.dart';
import '../helpers/widgets/banner_ad_widget.dart';
import '../models/profile.dart';
import '../providers/sound_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SoundsProvider soundsProvider = context.read<SoundsProvider>();
    ProfileProvider profileProvider = context.read<ProfileProvider>();
    bool isSoundMuted = context.select<SoundsProvider, bool>((provider) => provider.isSoundMuted);
    bool isClickMuted = context.select<SoundsProvider, bool>((provider) => provider.isClickMuted);
    Profile? profile = context.select<ProfileProvider, Profile?>((provider) => provider.profile);
    bool isNotificationEnabled = context.select<ProfileProvider, bool>((provider) => provider.isNotificationEnabled);
    if (profile == null) profileProvider.createLocalProfile();
    bool isDesktop = MediaQuery.of(context).size.width > 600;
    List<String> difficulties = ['Easy', 'Medium', 'Hard'];

    return Scaffold(
      bottomNavigationBar: bannerAdWidget(profile?.isPremiumMember ?? false),
      appBar: AppBar(
        centerTitle: true,
        leading: leadingButton(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: headingText(text: "SETTINGS"),
      ),
      body: ListView(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 30),
          // click and sound icon buttons
          if (!kIsWeb)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // click
                InkWell(
                  onTap: () async {
                    await soundsProvider.playClick();
                    await soundsProvider.toggleClick();
                  },
                  child: AnimatedNeumorphicContainer(
                      depth: 0,
                      color: Palette.primary,
                      width: 50,
                      height: 50,
                      radius: 25.0,
                      child: Center(
                        child: Icon(isClickMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 30),
                      )),
                ),
                const SizedBox(width: 15),
                // sound
                InkWell(
                  onTap: () async {
                    await soundsProvider.playClick();
                    await soundsProvider.toggleSound();
                  },
                  child: AnimatedNeumorphicContainer(
                      depth: 0,
                      color: Palette.primary,
                      width: 50,
                      height: 50,
                      radius: 25.0,
                      child: Center(
                        child: Icon(isSoundMuted ? Icons.music_off : Icons.music_note, color: Colors.white, size: 30),
                      )),
                ),
              ],
            ),
          if (!kIsWeb) const SizedBox(height: 15),
          SizedBox(
              width: isDesktop ? 500 : double.infinity, child: const Divider(color: Palette.primary, thickness: 1)),
          const SizedBox(height: 15),
          // others
          SizedBox(
              width: isDesktop ? 500 : double.infinity,
              child: Column(
                children: [
                  // difficulty level dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Align(alignment: Alignment.centerLeft, child: headingText(text: "Difficulty")),
                              const SizedBox(height: 5),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: bodyText(
                                      text: "Increasing difficulty reduces the amount of lives you have per game")),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        SizedBox(
                          width: 130,
                          child: DropdownButtonFormField<String>(
                            value: _difficultyLevel(profile!),
                            items: difficulties.map((String value) {
                              return DropdownMenuItem(
                                value: value,
                                child: bodyText(text: value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) async {
                              soundsProvider.playClick();
                              await profileProvider.updateDifficulty(_difficultyLevelInt(newValue!));
                              if (context.mounted) {
                                snackBarHelper(context,
                                    message: "Difficulty updated. Changes will be applied in the next game");
                              }
                            },
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Palette.primary,
                                  width: 1,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Palette.primary,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Palette.primary),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Palette.scaffold,
                                  width: 1,
                                ),
                              ),
                            ),
                            style: GoogleFonts.ntr(color: Colors.white, fontSize: 16),
                            dropdownColor: Palette.scaffold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Divider(color: Palette.primary, thickness: 1),
                  const SizedBox(height: 10),
                  // notification toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Align(alignment: Alignment.centerLeft, child: headingText(text: "Notifications")),
                              const SizedBox(height: 5),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child:
                                      bodyText(text: "Receive notifications when a new wordle is available to play")),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        SizedBox(
                          width: 130,
                          child: Switch(
                            value: isNotificationEnabled,
                            onChanged: (value) async {
                              soundsProvider.playClick();
                              await profileProvider.toggleNotifications();
                              if (context.mounted) snackBarHelper(context, message: "Notifications updated.");
                            },
                            activeTrackColor: Colors.white,
                            activeColor: Palette.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Divider(color: Palette.primary, thickness: 1),
                  const SizedBox(height: 10),
                  // contact us
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(
                          child: Column(
                            children: [
                              Align(alignment: Alignment.centerLeft, child: headingText(text: "Contact Us")),
                              const SizedBox(height: 5),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: bodyText(text: "Have a question or feedback? We'd love to hear from you!")),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        SizedBox(
                            width: 130,
                            child:
                                customButton(context, icon: Icons.contact_support_rounded, text: "Contact", onTap: () {
                              soundsProvider.playClick();
                              // TODO: add contact us functionality
                            })),
                      ])),
                  const SizedBox(height: 5),
                  const Divider(color: Palette.primary, thickness: 1),
                  const SizedBox(height: 10),
                  // privacy policy
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(
                          child: Column(
                            children: [
                              Align(alignment: Alignment.centerLeft, child: headingText(text: "Privacy Policy")),
                              const SizedBox(height: 5),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: bodyText(text: "Read our privacy policy to learn how we use your data")),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        SizedBox(
                            width: 130,
                            child: customButton(context, icon: Icons.privacy_tip_rounded, text: "View", onTap: () {
                              soundsProvider.playClick();
                              // TODO: add privacy policy functionality. Also review the privacy policy on sign in and sign up screens
                            })),
                      ])),
                ],
              )),
        ],
      ),
    );
  }

  String _difficultyLevel(Profile profile) {
    switch (profile.difficulty) {
      case 1:
        return "Easy";
      case 2:
        return "Medium";
      case 3:
        return "Hard";
      default:
        return "Easy";
    }
  }

  int _difficultyLevelInt(String difficulty) {
    switch (difficulty) {
      case "Easy":
        return 1;
      case "Medium":
        return 2;
      case "Hard":
        return 3;
      default:
        return 1;
    }
  }
}
