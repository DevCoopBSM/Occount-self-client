import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../services/item_service.dart';
import '../models/item_response.dart';

class ItemProvider extends ChangeNotifier {
  final ItemService _itemService;
  final Logger _logger = Logger('ItemProvider');

  final TextEditingController barcodeController = TextEditingController();
  final FocusNode barcodeFocusNode = FocusNode();

  bool _isLoading = false;
  String? _error;
  final List<String> _topList = [];

  ItemProvider(this._itemService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get topList => _topList;

  Future<ItemResponse?> fetchItemByCode(String barcode) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final normalizedBarcode = _itemService.normalizeBarcode(barcode);
      final item = await _itemService.getItemByCode(normalizedBarcode);
      _logger.info('📦 상품 조회 성공: ${item.itemName}');
      return item;
    } catch (e) {
      _logger.severe('❌ 상품 조회 에러: $e');
      _error = '상품 정보를 가져오는데 실패했습니다';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    barcodeController.dispose();
    barcodeFocusNode.dispose();
    _topList.clear();
    super.dispose();
  }
}
