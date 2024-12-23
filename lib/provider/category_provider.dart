import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/non_barcode_item_response.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService;
  final Logger _logger = Logger('CategoryProvider');

  List<String> _categories = [];
  String? _selectedCategory;
  final Map<String, List<NonBarcodeItemResponse>> _categoryItems = {};
  List<String>? _cachedCategories;
  bool _isLoading = false;
  String? _error;

  CategoryProvider(this._categoryService) {
    _initializeProvider();
  }

  List<String> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<NonBarcodeItemResponse> getCategoryItems(String category) =>
      _categoryItems[category] ?? [];

  Future<void> _initializeProvider() async {
    await loadCategories();
  }

  Future<void> loadCategories() async {
    if (_categories.isNotEmpty) {
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final categories = await _categoryService.getCategories();
      _categories = categories;

      if (_categories.isNotEmpty && _selectedCategory == null) {
        _selectedCategory = _categories.first;
        await loadItemsByCategory(_selectedCategory!);
      }
    } catch (e) {
      _error = '카테고리 목록을 불러오는데 실패했습니다';
      _logger.severe('❌ 카테고리 목록 로딩 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadItemsByCategory(String category) async {
    if (_categoryItems.containsKey(category)) {
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final items = await _categoryService.getItemsByCategory(category);
      _categoryItems[category] = items;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void selectCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    loadItemsByCategory(category);
    notifyListeners();
  }

  @override
  void dispose() {
    _categories.clear();
    _categoryItems.clear();
    _cachedCategories = null;
    super.dispose();
  }
}
