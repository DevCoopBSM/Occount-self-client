import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:logging/logging.dart';
import 'package:occount_self/utils/sound_utils.dart';

class PersonCounterService {
  WebSocketChannel? _channel;
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _currentAvgCount = 0;
  bool _isPlaying = false;
  bool hasEntered = false;
  int nonZeroCount = 0;
  int zeroCount = 0;
  Timer? _reconnectionTimer;
  bool _isConnecting = false;
  bool _isConnected = false;

  final Logger _logger = Logger('PersonCounterService');

  static const double presenceThreshold = 0.5;
  static const int stableCountThreshold = 3;
  static const int exitCountThreshold = 3;

  PersonCounterService() {
    _initWebSocket();
  }

  void _initWebSocket() {
    if (_isConnecting || _isConnected) return;
    _isConnecting = true;

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://occount.bsm-aripay.kr/ws/person_count'),
      );

      _channel!.stream.listen(
        _handleMessage,
        onError: (_) => _reconnectWebSocket(),
        onDone: _reconnectWebSocket,
      );

      _isConnected = true;
      _isConnecting = false;
    } catch (e) {
      _reconnectWebSocket();
    }
  }

  void _reconnectWebSocket() {
    _isConnected = false;
    _isConnecting = false;
    _channel?.sink.close();

    // 재연결 시도
    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(const Duration(seconds: 5), _initWebSocket);
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      if (data.containsKey('avg_count')) {
        _currentAvgCount = (data['avg_count'] as num).toDouble();
        _checkStableCount();
      }
    } catch (e) {
      _logger.severe('❌ 메시지 처리 오류: $e');
    }
  }

  void _checkStableCount() {
    if (_currentAvgCount > presenceThreshold) {
      nonZeroCount++;
      zeroCount = 0;

      if (nonZeroCount >= stableCountThreshold && !hasEntered) {
        _logger.info('👤 사람이 감지되었습니다 - 환영 메시지 재생');
        _playWelcomeMessage();
        hasEntered = true;
      }
    } else {
      zeroCount++;
      nonZeroCount = 0;

      if (zeroCount >= exitCountThreshold && hasEntered) {
        _logger.info('👻 사람이 떠났습니다 - 작별 메시지 재생');
        _playGoodbyeMessage();
        hasEntered = false;
      }
    }
  }

  Future<void> _playWelcomeMessage() async {
    if (!_isPlaying) {
      _isPlaying = true;
      try {
        await SoundUtils.playSound(SoundType.welcome);
        _logger.info('✅ 환영 메시지 재생 완료');
      } catch (e) {
        _logger.severe('❌ 환영 메시지 재생 오류: $e');
      } finally {
        _isPlaying = false;
      }
    }
  }

  Future<void> _playGoodbyeMessage() async {
    if (!_isPlaying) {
      _isPlaying = true;
      try {
        await SoundUtils.playSound(SoundType.goodbye);
        _logger.info('✅ 작별 메시지 재생 완료');
      } catch (e) {
        _logger.severe('❌ 작별 메시지 재생 오류: $e');
      } finally {
        _isPlaying = false;
      }
    }
  }

  void dispose() {
    _channel?.sink.close();
    _audioPlayer.dispose();
    _reconnectionTimer?.cancel();
  }
}
