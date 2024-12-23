import 'package:logging/logging.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../dto/event_item_response_dto.dart';

class EventService {
  final ApiClient _apiClient;
  final Logger _logger = Logger('EventService');

  EventService(this._apiClient);

  Future<List<EventItemResponseDto>> getEventList() async {
    try {
      return await _apiClient.get(
        ApiEndpoints.getEventItems,
        (json) {
          List<dynamic> jsonList = json as List;
          return jsonList
              .map((item) => EventItemResponseDto.fromJson(item))
              .toList();
        },
      );
    } catch (e) {
      _logger.severe('이벤트 상품 목록 조회 실패: $e');
      rethrow;
    }
  }
} 