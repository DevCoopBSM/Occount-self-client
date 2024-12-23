import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/category_provider.dart';
import '../../../provider/auth_provider.dart';
import '../../../models/cart_item.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/theme/devcoop_text_style.dart';

class ProductList extends StatelessWidget {
  const ProductList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (categoryProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (categoryProvider.error != null) {
      return Center(
        child: Text(
          categoryProvider.error!,
          style: DevCoopTextStyle.bold_20.copyWith(color: DevCoopColors.error),
        ),
      );
    }

    final selectedCategory = categoryProvider.selectedCategory;
    if (selectedCategory == null) {
      return const Center(
        child: Text(
          "카테고리를 선택해주세요",
          style: DevCoopTextStyle.bold_30,
        ),
      );
    }

    final items = categoryProvider.getCategoryItems(selectedCategory);
    if (items.isEmpty) {
      return Center(
        child: Text(
          "[$selectedCategory] 카테고리에 상품이 없습니다",
          style: DevCoopTextStyle.bold_30,
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildProductCard(context, item);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic item) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return InkWell(
      onTap: () {
        final cartItem = CartItem.fromNonBarcodeResponse(item);
        authProvider.addToCart(cartItem);
      },
      child: Card(
        elevation: 2,
        color: DevCoopColors.primaryLight,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.itemName,
                  style: DevCoopTextStyle.bold_20,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.itemPrice}원',
                  style: DevCoopTextStyle.medium_20,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
