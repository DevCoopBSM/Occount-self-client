import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';

class PersonCounterService {
  late WebSocketChannel _channel;
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _currentAvgCount = 0;
  bool _isPlaying = false;
  bool hasEntered = false;
  int nonZeroCount = 0; // 0이 아닌 값 카운트
  int zeroCount = 0; // 0 값 카운트
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

    if (_currentAvgCount > 0) {
      nonZeroCount++;
      zeroCount = 0; // 0 카운트 초기화
    } else {
      zeroCount++;
      nonZeroCount = 0; // 0이 아닌 카운트 초기화
    }

    // 0이 아닌 값이 2번 감지되면 웰컴 메시지
    if (nonZeroCount >= 2 && !hasEntered) {
      print('Playing welcome message');
      _playWelcomeMessage();
      hasEntered = true;
    }

    // 0 값이 2번 감지되면 굿바이 메시지
    if (zeroCount >= 2 && hasEntered) {
      print('Playing goodbye message');
      _playGoodbyeMessage();
      hasEntered = false;
    }
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
