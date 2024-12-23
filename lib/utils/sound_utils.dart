import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';

enum SoundType {
  click('click.mp3'),
  success('success.mp3'),
  error('error.mp3'),
  welcome('welcome.mp3'),
  goodbye('goodbye.mp3');

  final String fileName;
  const SoundType(this.fileName);
}

class SoundUtils {
  static final _logger = Logger('SoundUtils');
  static final Map<SoundType, List<AudioPlayer>> _playerPools = {};
  static final Map<SoundType, int> _currentIndices = {};
  static final Set<SoundType> _initializedTypes = {};

  static const _poolSize = 3; // 각 사운드 타입당 플레이어 수

  static Future<void> _initializeType(SoundType type) async {
    if (_initializedTypes.contains(type)) return;

    try {
      _playerPools[type] ??= List.generate(_poolSize, (_) => AudioPlayer());
      _currentIndices[type] ??= 0;

      final players = _playerPools[type]!;
      for (var player in players) {
        await player.setAsset('assets/audios/${type.fileName}');
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
      await player.stop();
      await player.setAsset('assets/audios/${type.fileName}');
      await player.setVolume(1.0);
      player.play();

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
