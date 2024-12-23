import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/category_provider.dart';
import '../../_constant/theme/devcoop_colors.dart';

class ProductTypeSelector extends StatelessWidget {
  const ProductTypeSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          alignment: Alignment.centerRight,
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: DevCoopColors.primary,
          ),
          child: DropdownButton<String>(
            underline: const SizedBox.shrink(),
            value: categoryProvider.selectedCategory,
            items: categoryProvider.categories
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
            onChanged: (category) {
              if (category != null) {
                categoryProvider.loadItemsByCategory(category);
              }
            },
          ),
        ),
      ],
    );
  }
}
