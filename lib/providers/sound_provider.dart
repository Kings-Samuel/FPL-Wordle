import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:fplwordle/helpers/utils/sec_storage.dart';

class SoundsProvider extends ChangeNotifier {
  static const String _click = 'assets/sound-effects/click.mp3';
  static const String _correct = 'assets/sound-effects/correct.mp3';
  static const String _cheer = 'assets/sound-effects/cheer.mp3';
  static const String _error = 'assets/sound-effects/error.mp3';
  static const String _gameOver = 'assets/sound-effects/game-over.mp3';
  static const String _gamemusic = 'assets/sound-effects/gamemusic.mp3';
  final _assetsAudioPlayer = AssetsAudioPlayer();
  bool _isSoundMuted = false;
  bool _isClickMuted = false;

  bool get isSoundMuted => _isSoundMuted;
  bool get isClickMuted => _isClickMuted;

  SoundsProvider() {
    _checkMuteSettings();
  }

  Future<void> _checkMuteSettings() async {
    String? isSoundMuted = await secStorage.read(key: 'isSoundMuted');
    String? isClickMuted = await secStorage.read(key: 'isClickMuted');

    _isSoundMuted = isSoundMuted == 'true' ? true : false;
    _isClickMuted = isClickMuted == 'true' ? true : false;

    notifyListeners();
  }

  Future<void> toggleClick() async {
    _isClickMuted = !_isClickMuted;
    await secStorage.write(key: 'isClickMuted', value: _isClickMuted.toString());
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _isSoundMuted = !_isSoundMuted;
    await secStorage.write(key: 'isSoundMuted', value: _isSoundMuted.toString());
    notifyListeners();
  }

  Future<void> playClick() async {
    if (!_isClickMuted) {
      await _assetsAudioPlayer.open(
        Audio(_click),
        autoStart: true,
        showNotification: false,
        respectSilentMode: false,
        playInBackground: PlayInBackground.disabledRestoreOnForeground,
        audioFocusStrategy: const AudioFocusStrategy.request(resumeAfterInterruption: true, resumeOthersPlayersAfterDone: true),
      );
    }
  }

  Future<void> playCorrect() async {
    if (!_isSoundMuted) {
      await _assetsAudioPlayer.open(
        Audio(_correct),
        autoStart: true,
        showNotification: false,
        respectSilentMode: false,
        playInBackground: PlayInBackground.disabledRestoreOnForeground,
        audioFocusStrategy: const AudioFocusStrategy.request(resumeAfterInterruption: true, resumeOthersPlayersAfterDone: true),
      );
    }
  }

  Future<void> playCheer() async {
    if (!_isSoundMuted) {
      await _assetsAudioPlayer.open(
        Audio(_cheer),
        autoStart: true,
        showNotification: false,
        respectSilentMode: false,
        playInBackground: PlayInBackground.disabledRestoreOnForeground,
        audioFocusStrategy: const AudioFocusStrategy.request(resumeAfterInterruption: true, resumeOthersPlayersAfterDone: true),
      );
    }
  }

  Future<void> playError() async {
    if (!_isSoundMuted) {
      await _assetsAudioPlayer.open(
        Audio(_error),
        autoStart: true,
        showNotification: false,
        respectSilentMode: false,
        playInBackground: PlayInBackground.disabledRestoreOnForeground,
        audioFocusStrategy: const AudioFocusStrategy.request(resumeAfterInterruption: true, resumeOthersPlayersAfterDone: true),
      );
    }
  }

  Future<void> playGameOver() async {
    if (!_isSoundMuted) {
      await _assetsAudioPlayer.open(
        Audio(_gameOver),
        autoStart: true,
        showNotification: false,
        respectSilentMode: false,
        playInBackground: PlayInBackground.disabledRestoreOnForeground,
        audioFocusStrategy: const AudioFocusStrategy.request(resumeAfterInterruption: true, resumeOthersPlayersAfterDone: true),
      );
    }
  }

  Future<void> playGameMusic() async {
    if (!_isSoundMuted) {
      await _assetsAudioPlayer.open(
        Audio(_gamemusic),
        autoStart: true,
        showNotification: false,
        respectSilentMode: false,
        loopMode: LoopMode.single,
        playInBackground: PlayInBackground.disabledRestoreOnForeground,
        audioFocusStrategy: const AudioFocusStrategy.request(resumeAfterInterruption: true, resumeOthersPlayersAfterDone: true),
      );
    }
  }
}
