import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class NavigationProvider with ChangeNotifier {
  final _logger = Logger('NavigationProvider');
  int _currentIndex = 0;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  int get currentIndex => _currentIndex;

  void updateCurrentPage(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      _logger.info('🔄 페이지 변경: $index');
      notifyListeners();
    }
  }
}
