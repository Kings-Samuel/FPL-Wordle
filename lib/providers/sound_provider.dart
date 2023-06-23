import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/foundation.dart';
import 'package:fplwordle/consts/shared_prefs_consts.dart';
import 'package:fplwordle/helpers/utils/init_sec_storage.dart';

class SoundsProvider extends ChangeNotifier {
  static const String _click = 'assets/sound-effects/click.mp3';
  static const String _correct = 'assets/sound-effects/correct.mp3';
  static const String _cheer = 'assets/sound-effects/cheer.mp3';
  static const String _error = 'assets/sound-effects/error.mp3';
  static const String _gameOver = 'assets/sound-effects/game-over.mp3';
  static const String _gamemusic = 'assets/sound-effects/gamemusic.mp3';
  final _assetsAudioPlayer = AssetsAudioPlayer();
  final _gameMusicPlayer = AssetsAudioPlayer();
  bool _isSoundMuted = false;
  bool _isClickMuted = false;

  bool get isSoundMuted => _isSoundMuted;
  bool get isClickMuted => _isClickMuted;

  SoundsProvider() {
    _checkMuteSettings();
  }

  Future<void> _checkMuteSettings() async {
    String? isSoundMuted = await secStorage.read(key: SharedPrefsConsts.isSoundMuted);
    String? isClickMuted = await secStorage.read(key: SharedPrefsConsts.isClickMuted);

    _isSoundMuted = isSoundMuted == 'true' ? true : false;
    _isClickMuted = isClickMuted == 'true' ? true : false;

    notifyListeners();
  }

  Future<void> toggleClick() async {
    _isClickMuted = !_isClickMuted;
    await secStorage.write(key: SharedPrefsConsts.isClickMuted, value: _isClickMuted.toString());
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _isSoundMuted = !_isSoundMuted;
    await secStorage.write(key: SharedPrefsConsts.isSoundMuted, value: _isSoundMuted.toString());
    if (_isSoundMuted) {
      await stopGameMusic();
    } else {
      startGameMusic();
    }
    notifyListeners();
  }

  Future<void> playClick() async {
    if (!_isClickMuted && !kIsWeb) {
      await pauseGameMusic();
      await _assetsAudioPlayer.open(
        Audio(_click),
        autoStart: true,
        showNotification: false,
        respectSilentMode: false,
        playInBackground: PlayInBackground.disabledRestoreOnForeground,
        audioFocusStrategy:
            const AudioFocusStrategy.request(resumeAfterInterruption: true, resumeOthersPlayersAfterDone: true),
      );
      await resumeGameMusic();
    }
  }

  Future<void> playCorrect() async {
    if (!_isSoundMuted && !kIsWeb) {
      await pauseGameMusic();
      await _assetsAudioPlayer.open(
        Audio(_correct),
        autoStart: true,
        showNotification: false,
        respectSilentMode: false,
        playInBackground: PlayInBackground.disabledRestoreOnForeground,
        audioFocusStrategy:
            const AudioFocusStrategy.request(resumeAfterInterruption: true, resumeOthersPlayersAfterDone: true),
      );
      await resumeGameMusic();
    }
  }

  Future<void> playCheer() async {
    if (!_isSoundMuted && !kIsWeb) {
      await pauseGameMusic();
      await _assetsAudioPlayer.open(
        Audio(_cheer),
        autoStart: true,
        showNotification: false,
        respectSilentMode: false,
        playInBackground: PlayInBackground.disabledRestoreOnForeground,
        audioFocusStrategy:
            const AudioFocusStrategy.request(resumeAfterInterruption: true, resumeOthersPlayersAfterDone: true),
      );
      await resumeGameMusic();
    }
  }

  Future<void> playError() async {
    if (!_isSoundMuted && !kIsWeb) {
      await pauseGameMusic();
      await _assetsAudioPlayer.open(
        Audio(_error),
        autoStart: true,
        showNotification: false,
        respectSilentMode: false,
        playInBackground: PlayInBackground.disabledRestoreOnForeground,
        audioFocusStrategy:
            const AudioFocusStrategy.request(resumeAfterInterruption: true, resumeOthersPlayersAfterDone: true),
      );
      await resumeGameMusic();
    }
  }

  Future<void> playGameOver() async {
    if (!_isSoundMuted && !kIsWeb) {
      await pauseGameMusic();
      await _assetsAudioPlayer.open(
        Audio(_gameOver),
        autoStart: true,
        showNotification: false,
        respectSilentMode: false,
        playInBackground: PlayInBackground.disabledRestoreOnForeground,
        audioFocusStrategy:
            const AudioFocusStrategy.request(resumeAfterInterruption: true, resumeOthersPlayersAfterDone: true),
      );
      await resumeGameMusic();
    }
  }

  Future<void> startGameMusic() async {
    bool isPlaying = _gameMusicPlayer.isPlaying.value;

    if (!_isSoundMuted && !kIsWeb && !isPlaying) {
      await _gameMusicPlayer.open(
        Audio(_gamemusic),
        autoStart: true,
        showNotification: false,
        respectSilentMode: false,
        loopMode: LoopMode.single,
        playInBackground: PlayInBackground.disabledRestoreOnForeground,
        audioFocusStrategy:
            const AudioFocusStrategy.request(resumeAfterInterruption: true, resumeOthersPlayersAfterDone: true),
      );
    }
  }

  Future<void> pauseGameMusic() async {
    if (!_isSoundMuted && !kIsWeb) {
      await _gameMusicPlayer.pause();
    }
  }

  Future<void> resumeGameMusic() async {
    if (!_isSoundMuted && !kIsWeb) {
      await _gameMusicPlayer.play();
    }
  }

  Future<void> stopGameMusic() async {
    if (!_isSoundMuted && !kIsWeb) {
      await _gameMusicPlayer.stop();
    }
  }
}
