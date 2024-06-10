import 'dart:convert';

import 'package:counter/ui/_constant/util/print.dart';
import 'package:http/http.dart' as http;
import 'package:counter/secure/db.dart';

Future<void> getTopList(Function(List<String>) onUpdate) async {
  final dbSecure = DbSecure();
  try {
    final response = await http.get(
      Uri.parse('http://${dbSecure.DB_HOST}/kiosk/item/top/list'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    printLog('Response status: ${response.statusCode}');
    printLog('Response body: ${response.body}');

    if (response.statusCode == 200) {
      // 응답 본문을 UTF-8로 디코드
      final decodedBody = utf8.decode(response.bodyBytes);
      printLog('Decoded body: $decodedBody');
      try {
        List<String> topList = List<String>.from(json.decode(decodedBody));
        onUpdate(topList);
      } catch (e) {
        printLog('JSON decode error: $e');
      }
    } else {
      printLog('Request failed with status: ${response.statusCode}');
    }
  } catch (e) {
    printLog('Error: $e');
  }
}
