import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:logging/logging.dart';
import 'package:counter/utils/sound_utils.dart';

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
  bool _isConnected = false; // 새로운 변수: 실제 연결 상태를 추적
  int _reconnectAttempts = 0;
  final Logger _logger = Logger('PersonCounterService');
  static const presenceThreshold = 0.5; // PRESENCE_THRESHOLD
  static const stableCountThreshold = 3; // STABLE_COUNT_THRESHOLD
  static const exitCountThreshold = 3; // EXIT_COUNT_THRESHOLD

  PersonCounterService() {
    _initWebSocket();
  }

  void _initWebSocket() {
    if (_isConnecting || _isConnected) return; // 이미 연결 중이거나 연결된 경우 중복 연결 방지
    _isConnecting = true;

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://occount.bsm-aripay.kr/ws/person_count'),
      );
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _logger.warning('WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          _logger.info('WebSocket connection closed');
          _handleDisconnection();
        },
      );
      _isConnected = true; // 연결 성공
      _isConnecting = false;
      _reconnectAttempts = 0;
      _logger.info('WebSocket connected successfully');
    } catch (e) {
      _logger.severe('Error initializing WebSocket: $e');
      _handleDisconnection();
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    _isConnecting = false;
    if (!_isConnected) {
      // 이미 연결이 끊어진 상태에서만 재연결 시도
      _scheduleReconnection();
    }
  }

  void _scheduleReconnection() {
    _reconnectionTimer?.cancel();
    final delay = Duration(seconds: _calculateBackoff());
    _reconnectionTimer = Timer(delay, () {
      if (!_isConnected && !_isConnecting) {
        // 연결되지 않은 상태에서만 재연결 시도
        _logger.info('Attempting to reconnect...');
        _initWebSocket();
      }
    });
  }

  int _calculateBackoff() {
    _reconnectAttempts++;
    return _reconnectAttempts.clamp(1, 6) * 5; // 5초에서 30초 사이로 제한
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      if (data.containsKey('avg_count')) {
        _currentAvgCount = (data['avg_count'] as num).toDouble();
        _logger.info('Current average count: $_currentAvgCount');
        _checkStableCount();
      } else {
        _logger.warning('Received unknown message type: $data');
      }
    } catch (e) {
      _logger.severe('Error handling message: $e');
    }
  }

  void _checkStableCount() {
    _logger.info('Checking stable count: $_currentAvgCount');

    if (_currentAvgCount > presenceThreshold) {
      nonZeroCount++;
      zeroCount = 0;

      // 안정적으로 사람이 감지된 경우에만 웰컴 메시지
      if (nonZeroCount >= stableCountThreshold && !hasEntered) {
        _logger.info('Playing welcome message');
        _playWelcomeMessage();
        hasEntered = true;
      }
    } else {
      zeroCount++;

      // 완전히 0이 아니어도, 임계값 이하로 떨어지면 카운트
      if (zeroCount >= exitCountThreshold && hasEntered) {
        nonZeroCount = 0; // 퇴장으로 판단될 때만 초기화
        _logger.info('Playing goodbye message');
        _playGoodbyeMessage();
        hasEntered = false;
      }
    }
  }

  Future<void> _playWelcomeMessage() async {
    if (!_isPlaying) {
      _isPlaying = true;
      try {
        _logger.info('Attempting to play welcome message');
        await SoundUtils.playSound(SoundType.welcome);
        _logger.info('Welcome message played successfully');
        const Duration(seconds: 2);
      } catch (e) {
        _logger.severe('Error playing welcome message: $e');
      } finally {
        _isPlaying = false;
      }
    }
  }

  Future<void> _playGoodbyeMessage() async {
    if (!_isPlaying) {
      _isPlaying = true;
      try {
        _logger.info('Attempting to play goodbye message');
        await SoundUtils.playSound(SoundType.goodbye);
        _logger.info('Goodbye message played successfully');
        const Duration(seconds: 2);
      } catch (e) {
        _logger.severe('Error playing goodbye message: $e');
      } finally {
        _isPlaying = false;
      }
    }
  }

  void dispose() {
    _logger.info('Disposing PersonCounterService');
    _channel?.sink.close();
    _audioPlayer.dispose();
    _reconnectionTimer?.cancel();
  }
}
