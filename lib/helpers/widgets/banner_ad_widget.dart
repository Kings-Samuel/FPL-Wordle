import 'dart:io';
import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/consts/ads_consts.dart';

Widget bannerAdWidget(bool isPremiumMember) {
  if (Platform.isAndroid || Platform.isIOS && !isPremiumMember) {
    return Container(
      alignment: Alignment.center,
      child: MaxAdView(
          adUnitId: AdConsts().banner,
          adFormat: AdFormat.banner,
          listener: AdViewAdListener(
              onAdLoadedCallback: (ad) {},
              onAdLoadFailedCallback: (adUnitId, error) {},
              onAdClickedCallback: (ad) {},
              onAdExpandedCallback: (ad) {},
              onAdCollapsedCallback: (ad) {})),
    );
  } else {
    return const SizedBox.shrink();
  }
}
