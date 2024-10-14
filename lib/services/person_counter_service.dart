import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:just_audio/just_audio.dart';

class PersonCounterService {
  late WebSocketChannel _channel;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _lastAvgCount = 0;

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
    final Map<String, dynamic> data = jsonDecode(message);
    final int currentAvgCount = data['avg_count'] ?? 0;

    if (currentAvgCount > _lastAvgCount) {
      _playWelcomeMessage();
    } else if (currentAvgCount < _lastAvgCount && currentAvgCount == 0) {
      _playGoodbyeMessage();
    }

    _lastAvgCount = currentAvgCount;
  }

  Future<void> _playWelcomeMessage() async {
    await _audioPlayer.setAsset('assets/audios/welcome.mp3');
    await _audioPlayer.play();
  }

  Future<void> _playGoodbyeMessage() async {
    await _audioPlayer.setAsset('assets/audios/goodbye.mp3');
    await _audioPlayer.play();
  }

  void dispose() {
    _channel.sink.close();
    _audioPlayer.dispose();
  }
}
