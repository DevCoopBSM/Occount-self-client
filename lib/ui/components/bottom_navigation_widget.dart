import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/bottom_navigation_controller.dart';
import '../_constant/theme/devcoop_colors.dart';

Widget bottomNavigationBarWidget(BottomNavigationController controller) {
  return Obx(() => BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code, size: 70),
            label: '결제하기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.password, size: 70),
            label: '핀 변경',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu, size: 70),
            label: '인기상품',
          ),
        ],
        onTap: controller.updateCurrentPage,
        currentIndex: controller.currentIndex.value,
        selectedItemColor: DevCoopColors.primary,
      ));
}
