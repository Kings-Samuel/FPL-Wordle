import 'dart:math';
import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/foundation.dart';
import 'package:fplwordle/consts/ads_consts.dart';

Map? _sdkConfiguration;

Map? get sdkConfiguration => _sdkConfiguration;

Future<void> initApplovinMax() async {
  if (!kIsWeb) {
    _sdkConfiguration = await AppLovinMAX.initialize("");
    AppLovinMAX.setHasUserConsent(true);
  }
}

var _rewardedAdRetryAttempt = 0;

void initializeRewardedAds() {
  if (!kIsWeb) {
    AppLovinMAX.setRewardedAdListener(RewardedAdListener(
        onAdLoadedCallback: (ad) {
          // Rewarded ad is ready to be shown. AppLovinMAX.isRewardedAdReady(_rewarded_ad_unit_id) will now return 'true'
          debugPrint('Rewarded ad loaded from ${ad.networkName}');

          // Reset retry attempt
          _rewardedAdRetryAttempt = 0;
        },
        onAdLoadFailedCallback: (adUnitId, error) {
          // Rewarded ad failed to load
          // We recommend retrying with exponentially higher delays up to a maximum delay (in this case 64 seconds)
          _rewardedAdRetryAttempt = _rewardedAdRetryAttempt + 1;

          int retryDelay = pow(2, min(6, _rewardedAdRetryAttempt)).toInt();
          debugPrint('Rewarded ad failed to load with code ${error.code} - retrying in ${retryDelay}s');

          Future.delayed(Duration(milliseconds: retryDelay * 1000), () {
            AppLovinMAX.loadRewardedAd(AdConsts().rewarded);
          });
        },
        onAdDisplayedCallback: (ad) {},
        onAdDisplayFailedCallback: (ad, error) {},
        onAdClickedCallback: (ad) {},
        onAdHiddenCallback: (ad) {},
        onAdReceivedRewardCallback: (ad, reward) {}));
  }
}
