import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../_constant/theme/devcoop_colors.dart';
import '../_constant/theme/devcoop_text_style.dart';
import '../../provider/item_provider.dart';
import '../../provider/category_provider.dart';

class SelfCounterWidget extends StatelessWidget {
  const SelfCounterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        if (categoryProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (categoryProvider.error != null) {
          return Center(child: Text(categoryProvider.error!));
        }

        return Consumer<ItemProvider>(
          builder: (context, itemProvider, child) {
            final topList = itemProvider.topList;
            return _SelfCounterContent(topList: topList);
          },
        );
      },
    );
  }
}

class _SelfCounterContent extends StatelessWidget {
  final List<String> topList;

  const _SelfCounterContent({
    Key? key,
    required this.topList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          width: 1.sw,
          padding: EdgeInsets.only(left: 12.w, top: 30.h),
          child: const Text(
            "학생들이 가장 많이 구매한 상품은 무엇일까?",
            style: DevCoopTextStyle.bold_30,
          ),
        ),
        _buildContentList(),
      ],
    );
  }

  Widget _buildContentList() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          Container(
            alignment: Alignment.centerLeft,
            width: 1.sw,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFECECEC),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(topList.length, (index) {
                final item = topList[index].split(",");
                return Container(
                  margin: const EdgeInsets.all(10),
                  color: index % 2 == 0
                      ? DevCoopColors.primary
                      : DevCoopColors.white,
                  child: ListTile(
                    shape: Border.all(
                      color: const Color(0xFFECECEC),
                      width: 2,
                    ),
                    title: Text(
                      item[0],
                      style: DevCoopTextStyle.medium_20,
                    ),
                    trailing: Text(
                      "${item[1]}개",
                      style: DevCoopTextStyle.medium_20,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
