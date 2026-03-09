import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMuted = false;
  double _bgmVolume = 0.5;
  final double _sfxVolume = 0.7;

  Future<void> initialize() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> playBGM(String url, {bool isAsset = true}) async {
    if (_isMuted) return;
    Source source = isAsset ? AssetSource(url) : UrlSource(url);
    await _bgmPlayer.play(source, volume: _bgmVolume);
  }

  Future<void> playSFX(String url, {bool isAsset = true}) async {
    if (_isMuted) return;
    Source source = isAsset ? AssetSource(url) : UrlSource(url);
    await _sfxPlayer.play(source, volume: _sfxVolume);
  }

  void stopBGM() {
    _bgmPlayer.stop();
  }

  void setVolume(double volume) {
    _bgmVolume = volume;
    _bgmPlayer.setVolume(volume);
  }

  void mute() {
    _isMuted = true;
    _bgmPlayer.setVolume(0);
    _sfxPlayer.setVolume(0);
  }

  void unmute() {
    _isMuted = false;
    _bgmPlayer.setVolume(_bgmVolume);
    _sfxPlayer.setVolume(_sfxVolume);
  }
}
