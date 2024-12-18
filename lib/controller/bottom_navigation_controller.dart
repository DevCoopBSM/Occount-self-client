import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../ui/barcode/barcode_page.dart';
import '../ui/pin/pin_change.dart';
import '../ui/components/self_counter_widget.dart';

class BottomNavigationController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void updateCurrentPage(int index) {
    currentIndex.value = index;
  }

  Widget get currentPage {
    switch (currentIndex.value) {
      case 0:
        return const BarcodePage();
      case 1:
        return const PinChange();
      case 2:
        return const SelfCounterWidget();
      default:
        return const BarcodePage();
    }
  }
}
