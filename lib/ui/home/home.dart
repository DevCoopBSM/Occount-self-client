import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../controller/bottom_navigation_controller.dart';
import '../components/bottom_navigation_widget.dart';

class Home extends GetView<BottomNavigationController> {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => controller.currentPage),
      bottomNavigationBar: bottomNavigationBarWidget(controller),
    );
  }
}
