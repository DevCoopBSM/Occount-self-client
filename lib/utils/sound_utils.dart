import 'package:audioplayers/audioplayers.dart';
import 'package:logging/logging.dart';

// 더 단순한 형태의 enum
enum SoundType {
  click,
  welcome,
  goodbye;

  String get fileName {
    switch (this) {
      case SoundType.click:
        return 'click.mp3';
      case SoundType.welcome:
        return 'welcome.mp3';
      case SoundType.goodbye:
        return 'goodbye.mp3';
    }
  }
}

class SoundUtils {
  static final Logger _logger = Logger('SoundUtils');

  static final Map<SoundType, List<AudioPlayer>> _playerPools = {
    for (var type in SoundType.values)
      type: List.generate(10, (_) => AudioPlayer())
  };

  static final Map<SoundType, int> _currentIndices = {
    for (var type in SoundType.values) type: 0
  };

  static final Set<SoundType> _initializedTypes = {};

  static Future<void> _initializeType(SoundType type) async {
    if (_initializedTypes.contains(type)) return;

    try {
      final players = _playerPools[type]!;
      for (var player in players) {
        await player.setSource(AssetSource('audios/${type.fileName}'));
        await player.setVolume(1.0);
      }
      _initializedTypes.add(type);
    } catch (e) {
      _logger.severe('Failed to initialize ${type.name} players: $e');
    }
  }

  static Future<void> playSound(SoundType type) async {
    try {
      await _initializeType(type);

      final players = _playerPools[type]!;
      final currentIndex = _currentIndices[type]!;
      final player = players[currentIndex];

      // 현재 플레이어 강제 초기화 및 재생
      await player.stop(); // 현재 재생 중인 것을 강제 중지
      await player
          .setSource(AssetSource('audios/${type.fileName}')); // 음원 강제 리로드
      await player.setVolume(1.0);
      player.resume(); // 새로운 재생 시작

      // 다음 플레이어로 이동
      _currentIndices[type] = (currentIndex + 1) % players.length;
    } catch (e) {
      _logger.severe('Failed to play ${type.name} sound: $e');
    }
  }

  static void dispose() {
    try {
      for (var players in _playerPools.values) {
        for (var player in players) {
          player.stop();
          player.dispose();
        }
      }
      _playerPools.clear();
      _currentIndices.clear();
      _initializedTypes.clear();
    } catch (e) {
      _logger.severe('Error disposing sound utils: $e');
    }
  }
}
