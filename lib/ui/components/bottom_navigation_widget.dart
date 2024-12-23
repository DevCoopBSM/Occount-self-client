import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/navigation_provider.dart';
import '../_constant/theme/devcoop_colors.dart';

class BottomNavigationWidget extends StatelessWidget {
  const BottomNavigationWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);

    return BottomNavigationBar(
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
      onTap: navigationProvider.updateCurrentPage,
      currentIndex: navigationProvider.currentIndex,
      selectedItemColor: DevCoopColors.primary,
    );
  }
}
