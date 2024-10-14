import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';

class PersonCounterService {
  late WebSocketChannel _channel;
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _currentAvgCount = 0;
  bool _isPlaying = false;
  bool hasEntered = false;  // 사람이 들어왔는지 여부

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
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      print('Error initializing WebSocket: $e');
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      _currentAvgCount = (data['avg_count'] as num).toDouble();
      print('Current average count: $_currentAvgCount');

      // 안정화 타이머 비활성화
      //_stabilityTimer?.cancel();
      //_stabilityTimer = Timer(Duration(seconds: 2), _checkStableCount);

      _checkStableCount();  // 바로 실행해보기
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  void _checkStableCount() {
    print('Checking stable count: $_currentAvgCount');

    // 0이 아닌 값이 들어왔을 때 "어서오세요"를 한 번만 재생
    if (_currentAvgCount != 0 && !hasEntered) {
      print('Playing welcome message');
      _playWelcomeMessage();
      hasEntered = true;  // 사람이 들어왔으므로 "어서오세요"는 더 이상 재생하지 않음
    }

    // 0이 되었을 때 "안녕히 가세요" 메시지 재생하고 다시 "어서오세요" 가능 상태로 초기화
    else if (_currentAvgCount == 0 && hasEntered) {
      print('Playing goodbye message');
      _playGoodbyeMessage();
      hasEntered = false;  // 사람이 나갔으므로 "어서오세요"를 다시 재생할 수 있게 함
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
    //_stabilityTimer?.cancel();
  }
}
