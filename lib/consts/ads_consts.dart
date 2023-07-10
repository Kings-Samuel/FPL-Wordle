import 'dart:io';

class AdConsts {
  static const String  sdkKey = "2Zs6IS8BhG69VeaGXePrOAxuuTcHUdP8flkaWshe9ciQqCIxevn4Tl7z1TTfMrb04Ey_SJtJw9suB0rMlVB6lL";
  static const String  _bannerAndroid = "b77e6a72ce5c6e8b";
  static const String  _rewardedAndroid = "63005bd53effef38";
  static const String  _banneriOS = "banner";
  static const String  _rewardediOS = "banner";
  final String banner = Platform.isAndroid ? _bannerAndroid : _banneriOS;
  final String rewarded = Platform.isAndroid ? _rewardedAndroid : _rewardediOS;
}
