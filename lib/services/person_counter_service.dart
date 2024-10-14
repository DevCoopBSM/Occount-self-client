import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';

class PersonCounterService {
  late WebSocketChannel _channel;
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _currentAvgCount = 0;
  bool _isPlaying = false;
  bool hasEntered = false;
  Timer? _reconnectionTimer;

  PersonCounterService() {
    _initWebSocket();
  }

  void _initWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://occount.bsm-aripay.kr/ws/person_count'),
      );
      _channel.stream.listen(
        _handleMessage,
        onError: (error) {
          print('WebSocket error: $error');
          _scheduleReconnection();
        },
        onDone: () {
          print('WebSocket connection closed');
          _scheduleReconnection();
        },
      );
    } catch (e) {
      print('Error initializing WebSocket: $e');
      _scheduleReconnection();
    }
  }

  void _scheduleReconnection() {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      print('Attempting to reconnect...');
      _initWebSocket();
    });
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      _currentAvgCount = (data['avg_count'] as num).toDouble();
      print('Current average count: $_currentAvgCount');

      _checkStableCount();
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  void _checkStableCount() {
    print('Checking stable count: $_currentAvgCount');

    bool isSignificantChange = _isSignificantChange(_currentAvgCount);

    if (isSignificantChange && _currentAvgCount > 0 && !hasEntered) {
      print('Playing welcome message');
      _playWelcomeMessage();
      hasEntered = true;
    } else if (isSignificantChange && _currentAvgCount == 0 && hasEntered) {
      print('Playing goodbye message');
      _playGoodbyeMessage();
      hasEntered = false;
    }
  }

  bool _isSignificantChange(double count) {
    // 소수점 둘째 자리까지만 고려
    double roundedCount = (count * 100).round() / 100;
    
    // 0, 0.5, 1, 1.5, 2 등의 값일 때만 유의미한 변화로 간주
    return (roundedCount * 2).round() == roundedCount * 2;
  }

  Future<void> _playWelcomeMessage() async {
    if (!_isPlaying) {
      _isPlaying = true;
      try {
        print('Attempting to play welcome message');
        await _audioPlayer.play(AssetSource('audios/welcome.mp3'));
        print('Welcome message played successfully');
        await Future.delayed(Duration(seconds: 2));
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
        print('Attempting to play goodbye message');
        await _audioPlayer.play(AssetSource('audios/goodbye.mp3'));
        print('Goodbye message played successfully');
        await Future.delayed(Duration(seconds: 2));
      } catch (e) {
        print('Error playing goodbye message: $e');
      } finally {
        _isPlaying = false;
      }
    }
  }

  void dispose() {
    print('Disposing PersonCounterService');
    _channel.sink.close();
    _audioPlayer.dispose();
    _reconnectionTimer?.cancel();
  }
}
