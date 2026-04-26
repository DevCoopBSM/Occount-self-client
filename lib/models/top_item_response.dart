class TopItemResponse {
  final String itemName;
  final int totalSales;

  TopItemResponse({
    required this.itemName,
    required this.totalSales,
  });

  factory TopItemResponse.fromJson(Map<String, dynamic> json) {
    return TopItemResponse(
      itemName: json['item_name'] as String,
      totalSales: json['total_sales'] as int,
    );
  }
}
