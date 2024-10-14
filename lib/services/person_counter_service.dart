import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';

class PersonCounterService {
  late WebSocketChannel _channel;
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _lastAvgCount = 0;

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
      final double currentAvgCount = (data['avg_count'] as num).toDouble();

      if (currentAvgCount > _lastAvgCount) {
        _playWelcomeMessage();
      } else if (currentAvgCount < _lastAvgCount && currentAvgCount == 0) {
        _playGoodbyeMessage();
      }

      _lastAvgCount = currentAvgCount;
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  Future<void> _playWelcomeMessage() async {
    try {
      await _audioPlayer.play(AssetSource('audios/welcome.mp3'));
    } catch (e) {
      print('Error playing welcome message: $e');
    }
  }

  Future<void> _playGoodbyeMessage() async {
    try {
      await _audioPlayer.play(AssetSource('audios/goodbye.mp3'));
    } catch (e) {
      print('Error playing goodbye message: $e');
    }
  }

  void dispose() {
    _channel.sink.close();
    _audioPlayer.dispose();
  }
}
