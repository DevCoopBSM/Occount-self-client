import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';

class PersonCounterService {
  late WebSocketChannel _channel;
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _lastStableAvgCount = 0;
  double _currentAvgCount = 0;
  Timer? _stabilityTimer;
  bool _isPlaying = false;

  PersonCounterService() {
    _initWebSocket();
  }

  void _initWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://occount.bsm-aripay.kr/ws/person_count'),
      );
      _channel.stream.listen(_handleMessage, onError: (error) {
        print('WebSocket error: $error');
      });
    } catch (e) {
      print('Error initializing WebSocket: $e');
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      _currentAvgCount = (data['avg_count'] as num).toDouble();

      // 안정화 타이머 재설정
      _stabilityTimer?.cancel();
      _stabilityTimer = Timer(Duration(seconds: 2), _checkStableCount);
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  void _checkStableCount() {
    if (_currentAvgCount > _lastStableAvgCount && _currentAvgCount >= 1) {
      _playWelcomeMessage();
    } else if (_currentAvgCount < _lastStableAvgCount &&
        _currentAvgCount == 0) {
      _playGoodbyeMessage();
    }
    _lastStableAvgCount = _currentAvgCount;
  }

  Future<void> _playWelcomeMessage() async {
    if (!_isPlaying) {
      _isPlaying = true;
      try {
        await _audioPlayer.play(AssetSource('audios/welcome.mp3'));
        await Future.delayed(Duration(seconds: 2)); // 음성 재생 시간을 고려한 지연
      } catch (e) {
        print('Error playing welcome message: $e');
      } finally {
        _isPlaying = false;
      }
    }
  }

  Future<void> _playGoodbyeMessage() async {
    if (!_isPlaying) {
      _isPlaying = true;
      try {
        await _audioPlayer.play(AssetSource('audios/goodbye.mp3'));
        await Future.delayed(Duration(seconds: 2)); // 음성 재생 시간을 고려한 지연
      } catch (e) {
        print('Error playing goodbye message: $e');
      } finally {
        _isPlaying = false;
      }
    }
  }

  void dispose() {
    _channel.sink.close();
    _audioPlayer.dispose();
    _stabilityTimer?.cancel();
  }
}
