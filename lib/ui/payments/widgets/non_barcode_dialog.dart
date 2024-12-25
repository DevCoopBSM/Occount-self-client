import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/payment_provider.dart';
import '../../../models/non_barcode_item_response.dart';
import '../../../models/cart_item.dart';
import '../../_constant/theme/devcoop_colors.dart';
import '../../_constant/theme/devcoop_text_style.dart';
import '../../_constant/util/number_format_util.dart';
import '../../_constant/component/button.dart';
import '../../../provider/auth_provider.dart';

class NonBarcodeDialog extends StatefulWidget {
  const NonBarcodeDialog({Key? key}) : super(key: key);

  @override
  State<NonBarcodeDialog> createState() => _NonBarcodeDialogState();
}

class _NonBarcodeDialogState extends State<NonBarcodeDialog> {
  String _selectedCategory = '전체';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaymentProvider>(context, listen: false)
          .loadNonBarcodeItems();
    });
  }

  void _addItemToCart(BuildContext context, NonBarcodeItemResponse item) {
    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);
    paymentProvider.addNonBarcodeItem(context, item);

    // 현재 장바구니의 총액 계산 및 스낵바 표시
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final totalAmount = authProvider.cartItems.fold<int>(
      0,
      (sum, item) => sum + (item.itemPrice * item.quantity),
    );

    // 스낵바를 오버레이로 표시
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.1, // 화면 상단에서 10% 위치
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item.itemName} 상품이 추가되었습니다.',
                  style: DevCoopTextStyle.bold_20,
                ),
                const SizedBox(height: 8),
                Text(
                  '총 금액: ${NumberFormatUtil.convert1000Number(totalAmount)}원',
                  style: DevCoopTextStyle.bold_20,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // 2초 후 제거
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '바코드 없는 상품',
                  style: DevCoopTextStyle.bold_30.copyWith(
                    color: DevCoopColors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<PaymentProvider>(
                builder: (context, paymentProvider, _) {
                  if (paymentProvider.nonBarcodeItems.isEmpty) {
                    return const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final categories = [
                    '전체',
                    ...getUniqueCategories(paymentProvider.nonBarcodeItems)
                  ];

                  final filteredItems = filterItemsByCategory(
                    paymentProvider.nonBarcodeItems,
                    _selectedCategory,
                  );

                  return Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: FilterChip(
                                  label: Text(categories[index]),
                                  selected:
                                      _selectedCategory == categories[index],
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = categories[index];
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: mainTextButton(
                                  color: DevCoopColors.grey,
                                  text: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.itemName,
                                                style: DevCoopTextStyle.bold_20,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                item.itemCategory,
                                                style: DevCoopTextStyle
                                                    .medium_20
                                                    .copyWith(
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${NumberFormatUtil.convert1000Number(item.itemPrice)}원',
                                          style: DevCoopTextStyle.bold_20,
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () {
                                    _addItemToCart(context, item);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            mainTextButton(
              text: '닫기',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  List<String> getUniqueCategories(List<NonBarcodeItemResponse> items) {
    return items.map((e) => e.itemCategory).toSet().toList()..sort();
  }

  List<NonBarcodeItemResponse> filterItemsByCategory(
    List<NonBarcodeItemResponse> items,
    String category,
  ) {
    if (category == '전체') return items;
    return items.where((item) => item.itemCategory == category).toList();
  }
}
