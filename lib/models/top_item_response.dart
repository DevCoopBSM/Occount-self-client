class TopItemResponse {
  final String itemName;
  final int totalSales;

  TopItemResponse({
    required this.itemName,
    required this.totalSales,
  });

  factory TopItemResponse.fromJson(Map<String, dynamic> json) {
    return TopItemResponse(
      itemName: json['itemName'] as String,
      totalSales: json['totalSales'] as int,
    );
  }
}
