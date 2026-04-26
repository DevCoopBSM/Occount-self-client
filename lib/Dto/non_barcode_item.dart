class NonBarcodeItem {
  final String itemName;
  final int itemPrice;

  NonBarcodeItem({required this.itemName, required this.itemPrice});

  factory NonBarcodeItem.fromJson(Map<String, dynamic> json) {
    return NonBarcodeItem(
      itemName: json['item_name'],
      itemPrice: json['item_price'],
    );
  }
}
