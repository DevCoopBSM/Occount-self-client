import 'dart:async';
import 'dart:convert';

import 'package:counter/controller/payments_api.dart';
import 'package:counter/dto/event_item_response_dto.dart';
import 'package:counter/dto/non_barcode_item.dart';
import 'package:counter/secure/db.dart';
import 'package:counter/ui/_constant/theme/devcoop_colors.dart';
import 'package:counter/ui/_constant/theme/devcoop_text_style.dart';
import 'package:counter/ui/_constant/util/number_format_util.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../dto/item_response_dto.dart';
import '../_constant/component/button.dart';
import 'widgets/payments_popup.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({Key? key}) : super(key: key);

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  String savedStudentName = '';
  int savedPoint = 0;
  int totalPrice = 0;
  String savedCodeNumber = '';
  List<ItemResponseDto> itemResponses = [];
  List<EventItemResponseDto> eventItemList = [];
  final dbSecure = DbSecure();
  String accessToken = '';
  bool isButtonDisabled = false;
  Color dropdownColor = DevCoopColors.primary;
  String? selectedDropdown = "바코드 없는 상품";
  List<NonBarcodeItem> futureItems = [];
  bool isLoading = false;
  bool isDropDownClick = false;

  TextEditingController barcodeController = TextEditingController();
  FocusNode barcodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadAccessToken();
    await fetchNonBarcodeItems();
    await loadUserData();
  }

  Future<void> _loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      accessToken = prefs.getString('accessToken') ?? '';
    });

    if (accessToken.isEmpty) {
      Get.offAllNamed("/"); // 토큰이 없으면 로그인 페이지로
    }
  }

  Future<void> loadUserData() async {
    try {
      final response = await http.get(
        Uri.parse('${dbSecure.DB_HOST}/kiosk/user/user-info'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        SharedPreferences sharedPreferences =
            await SharedPreferences.getInstance();
        await sharedPreferences.setInt(
            'userPoint', responseData['userPoint'] ?? 0);
        await sharedPreferences.setString(
            'userName', responseData['userName'] ?? '');

        setState(() {
          savedPoint = responseData['userPoint'] ?? 0;
          savedStudentName = responseData['userName'] ?? '';
          savedCodeNumber = sharedPreferences.getString('userCode') ?? '';
        });
      }
    } catch (e) {
      print('사용자 정보 갱신 실패: $e');
    }
  }

  Future<void> fetchNonBarcodeItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      final response = await http.get(
        Uri.parse('${dbSecure.DB_HOST}/kiosk/non-barcode-item'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);

        // 데이터를 setState로 업데이트
        setState(() {
          futureItems = jsonResponse
              .map((item) => NonBarcodeItem.fromJson(item))
              .toList();
          isLoading = false; // 데이터 로드 완료 후 로딩 상태 해제
        });
      } else {
        throw Exception('Failed to load items');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  void showPaymentsPopup(String message, bool isError) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return paymentsPopUp(context, message, isError);
      },
    );
  }

  Future<void> fetchItemData(String barcode, int quantity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse('${dbSecure.DB_HOST}/kiosk/item?barcode=$barcode'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          final List<dynamic> itemJsonList =
              jsonDecode(utf8.decode(response.bodyBytes));
          print(itemJsonList);

          for (var itemJson in itemJsonList) {
            final String itemName = itemJson['itemName'];
            final int itemPrice = itemJson['itemPrice']; // itemPrice is now int
            final int itemQuantity = itemJson['quantity'];
            final String eventStatus = itemJson['eventStatus'];

            final existingItemIndex = itemResponses.indexWhere(
              (existingItem) => existingItem.itemId == barcode,
            );

            if (existingItemIndex != -1) {
              final existingItem = itemResponses[existingItemIndex];
              existingItem.quantity += itemQuantity;
              totalPrice += existingItem.itemPrice * itemQuantity;
              itemResponses[existingItemIndex] = existingItem;
            } else {
              final item = ItemResponseDto(
                itemName: itemName,
                itemPrice: itemPrice,
                itemId: barcode,
                quantity: itemQuantity,
                type: eventStatus,
              );

              print("eventStatus = $eventStatus");
              itemResponses.add(item);

              if (eventStatus == 'NONE') {
                totalPrice += itemPrice * itemQuantity;
              } else if (eventStatus == 'ONE_PLUS_ONE') {
                // Assuming ONE_PLUS_ONE means a discount, handle accordingly
                totalPrice += (itemPrice * itemQuantity / 2).toInt();
              }
            }
          }
        });
      } else {
        print("Failed to load item data: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> payments(List<ItemResponseDto> items) async {
    try {
      String apiUrl = '${dbSecure.DB_HOST}/kiosk/executePayments';

      // API 요청 함수 호출
      final response = await executePaymentRequest(apiUrl, accessToken,
          savedCodeNumber, savedStudentName, totalPrice, items);

      // 응답을 UTF-8로 디코딩하여 변수에 저장합니다.
      String responseBody = utf8.decode(response.bodyBytes);

      // JSON 파싱
      var decodedResponse = json.decode(responseBody);

      // 디코드된 응답을 출력합니다.

      if (response.statusCode == 200) {
        if (decodedResponse['status'] == 'success') {
          int remainingPoints = decodedResponse['remainingPoints'];
          String message =
              decodedResponse['message'] + "\n남은 잔액: $remainingPoints";
          showPaymentsPopup(
            message,
            false,
          );
        } else {
          showPaymentsPopup(
            decodedResponse['message'],
            true,
          );
        }
      } else {
        showPaymentsPopup(
          '에러: ${decodedResponse['message']}',
          true,
        );
      }
    } catch (e) {
      if (e is http.Response) {
        String responseBody = utf8.decode(e.bodyBytes);
        var decodedResponse = json.decode(responseBody);
        showPaymentsPopup(
          '예상치 못한 에러: ${decodedResponse['message']}',
          true,
        );
      } else {
        showPaymentsPopup(
          '예상치 못한 에러: ${e.toString()}',
          true,
        );
      }
    }
  }

  Future<void> _handlePayment() async {
    // onTap 콜백을 async로 선언하여 비동기 처리 가능
    if (savedPoint - totalPrice >= 0) {
      await payments(itemResponses);
    } else {
      showPaymentsPopup(
        "잔액이 부족합니다",
        true,
      );
    }
  }

  Function()? _debounce(Function()? func, int milliseconds) {
    bool isButtonPressed = false;
    return () {
      if (!isButtonPressed) {
        isButtonPressed = true;
        func?.call();
        Future.delayed(Duration(milliseconds: milliseconds), () {
          isButtonPressed = false;
        });
      }
    };
  }

  void handleBarcodeSubmit() {
    String barcode = barcodeController.text;

    int quantity = 1;

    if (barcode.isNotEmpty) {
      fetchItemData(
        barcode,
        quantity,
      );

      // 상품 선택 후 바코드 입력창 초기화
      barcodeController.clear();
    }
  }

  @override
  void dispose() {
    barcodeController.dispose();
    barcodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(barcodeFocusNode);
    return ScreenUtilInit(
      builder: (context, child) => Scaffold(
        body: GestureDetector(
          onTap: () {
            barcodeFocusNode.unfocus();
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people,
                      color: DevCoopColors.black,
                      size: 20.0,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => {
                              Get.offAllNamed("/barcode"),
                            },
                            child: Text(
                              accessToken.isEmpty
                                  ? "로그인하기"
                                  : "$savedStudentName님",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            accessToken.isEmpty
                                ? ""
                                : "${savedPoint.toString()}원",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: Row(
                  children: [
                    // Left container with scrolling
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProductSelect(),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  alignment: Alignment.centerRight,
                                  width: 160,
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: DevCoopColors.primary,
                                  ),
                                  child: DropdownButton<String>(
                                    underline: const SizedBox.shrink(),
                                    value: selectedDropdown,
                                    items: <String>["바코드 없는 상품", "행사상품"]
                                        .map<DropdownMenuItem<String>>(
                                            (String value) {
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
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedDropdown = newValue;
                                        if (selectedDropdown == "바코드 없는 상품") {
                                          fetchNonBarcodeItems(); // 데이터 재요청
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: DevCoopColors.primary,
                                    ),
                                  )
                                : selectedDropdown == "바코드 없는 상품"
                                    ? Expanded(
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            return Container(
                                              height: constraints.maxHeight,
                                              child: SingleChildScrollView(
                                                child: ListView.builder(
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  itemCount: futureItems.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          bool itemExists =
                                                              false;
                                                          for (var response
                                                              in itemResponses) {
                                                            if (response
                                                                    .itemName ==
                                                                futureItems[
                                                                        index]
                                                                    .itemName) {
                                                              response
                                                                  .quantity += 1;
                                                              totalPrice +=
                                                                  futureItems[
                                                                          index]
                                                                      .itemPrice;
                                                              itemExists = true;
                                                              break;
                                                            }
                                                          }
                                                          if (!itemExists) {
                                                            itemResponses.add(
                                                              ItemResponseDto(
                                                                itemName:
                                                                    futureItems[
                                                                            index]
                                                                        .itemName,
                                                                itemPrice:
                                                                    futureItems[
                                                                            index]
                                                                        .itemPrice,
                                                                itemId: futureItems[
                                                                        index]
                                                                    .itemName,
                                                                quantity: 1,
                                                                type: 'NONE',
                                                              ),
                                                            );
                                                            totalPrice +=
                                                                futureItems[
                                                                        index]
                                                                    .itemPrice;
                                                          }
                                                        });
                                                      },
                                                      child: Container(
                                                        margin: const EdgeInsets
                                                            .only(top: 10),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isDropDownClick
                                                              ? dropdownColor
                                                              : index % 2 == 0
                                                                  ? DevCoopColors
                                                                      .primaryLight
                                                                  : DevCoopColors
                                                                      .grey,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              futureItems[index]
                                                                  .itemName,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            Text(
                                                              '${futureItems[index].itemPrice}원',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : const Text(
                                        "행사상품이 없습니다",
                                        style: DevCoopTextStyle.bold_30,
                                      ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right container for payment details
                    Expanded(
                      flex: 2, // 오른쪽 컨테이너의 flex 값 (더 크게 설정)
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const Divider(color: Colors.black, thickness: 4),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 30,
                                ),
                                child: Column(
                                  children: [
                                    paymentsItem(
                                      itemName: '상품 이름',
                                      // ItemResponseDto의 Getter 사용
                                      type: "이벤트",
                                      center: '수량',
                                      plus: "",
                                      minus: "-",
                                      rightText: '상품 가격',
                                      contentsTitle: true,
                                    ),
                                    const SizedBox(
                                      height: 30,
                                    ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            for (int i = 0;
                                                i < itemResponses.length;
                                                i++) ...[
                                              paymentsItem(
                                                itemName:
                                                    itemResponses[i].itemName,
                                                // eventStatus가 'NONE'일 경우 'NONE'을 출력
                                                // eventStatus가 '1+1'일 경우 '1+1'을 출력
                                                type: itemResponses[i].type ==
                                                        'NONE'
                                                    ? '일 반'
                                                    : '1 + 1',
                                                center:
                                                    itemResponses[i].quantity,
                                                plus: "+",
                                                minus: "-",
                                                rightText: itemResponses[i]
                                                    .itemPrice
                                                    .toString(),
                                                totalText: false,
                                              ),
                                              if (i <
                                                  itemResponses.length - 1) ...[
                                                const SizedBox(
                                                  height: 15,
                                                ),
                                              ],
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(
                              color: Colors.black,
                              thickness: 4,
                              height: 4,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 40,
                                  ),
                                  child: savedPoint - totalPrice >= 0
                                      ? paymentsItem(
                                          itemName: '총 가격',
                                          // ItemResponseDto의 Getter 사용
                                          type: "",
                                          center: itemResponses
                                              .map<int>((item) => item.quantity)
                                              .fold<int>(
                                                  0,
                                                  (previousValue, element) =>
                                                      previousValue + element),
                                          plus: "",
                                          minus: "",
                                          rightText: totalPrice.toString(),
                                        )
                                      : const Text(
                                          "잔액이 부족합니다",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    mainTextButton(
                                      text: const Row(children: [
                                        Icon(
                                          Icons.delete,
                                          weight: 20,
                                        ),
                                        Text(
                                          "삭제",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      ]),
                                      onTap: () {
                                        setState(() {
                                          itemResponses.clear();
                                          totalPrice = 0;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 20),
                                    mainTextButton(
                                      text: const Row(children: [
                                        Icon(
                                          Icons.logout,
                                          weight: 20,
                                        ),
                                        Text(
                                          "홈으로",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      ]),
                                      onTap: () {
                                        removeUserData();
                                        Get.offAllNamed("/");
                                      },
                                    ),
                                    const SizedBox(width: 20),
                                    mainTextButton(
                                      text: const Row(children: [
                                        Icon(
                                          Icons.account_balance_wallet,
                                          weight: 20,
                                        ),
                                        Text(
                                          "셀프 충전",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      ]),
                                      onTap: handleSelfCharge,
                                    ),
                                    const SizedBox(width: 20),
                                    mainTextButton(
                                      text: const Row(children: [
                                        Icon(
                                          Icons.payment,
                                          weight: 20,
                                        ),
                                        Text(
                                          "결제",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      ]),
                                      isButtonDisabled: isButtonDisabled,
                                      onTap: _debounce(() async {
                                        setState(() {
                                          isButtonDisabled = true;
                                        });
                                        await _handlePayment();
                                        setState(() {
                                          isButtonDisabled = true;
                                        });
                                      }, 5000),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 20.h,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Row _buildProductSelect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(left: 20),
                height: 60.0,
                width: 300.0,
                child: TextFormField(
                  onFieldSubmitted: (_) => handleBarcodeSubmit(),
                  controller: barcodeController,
                  focusNode: barcodeFocusNode,
                  decoration: const InputDecoration(
                    hintText: '상품 바코드를 입력해주세요',
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: DevCoopColors.transparent), // 기본 테두리 색상
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: DevCoopColors.grey), // 포커스 상태의 색상
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: DevCoopColors.transparent), // 일반 상태의 색상
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        mainTextButton(
          text: const Icon(
            Icons.check,
            weight: 10.0,
          ),
          onTap: () => handleBarcodeSubmit(),
        ),
      ],
    );
  }

  Row paymentsItem({
    required String itemName,
    required String type,
    required dynamic center,
    required String plus,
    required String minus,
    int? right,
    String? rightText,
    bool contentsTitle = false,
    bool totalText = true,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            itemName,
            style: contentsTitle
                ? DevCoopTextStyle.medium_30.copyWith(
                    color: DevCoopColors.black,
                  )
                : totalText
                    ? DevCoopTextStyle.bold_30.copyWith(
                        color: DevCoopColors.black,
                      )
                    : DevCoopTextStyle.light_30.copyWith(
                        color: DevCoopColors.black,
                      ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          // margin: const EdgeInsets.only(left: 40),
          alignment: Alignment.centerRight,
          width: 100,
          child: Text(
            type,
            style: contentsTitle
                ? DevCoopTextStyle.medium_30.copyWith(
                    color: DevCoopColors.black,
                  )
                : totalText
                    ? DevCoopTextStyle.medium_30.copyWith(
                        color: DevCoopColors.black,
                      )
                    : DevCoopTextStyle.medium_30.copyWith(
                        color: DevCoopColors.error,
                      ),
          ),
        ),
        Container(
          width: 155,
          alignment: Alignment.centerRight,
          child: Text(
            "$center",
            style: contentsTitle
                ? DevCoopTextStyle.medium_30.copyWith(
                    color: DevCoopColors.black,
                  )
                : totalText
                    ? DevCoopTextStyle.bold_30.copyWith(
                        color: DevCoopColors.black,
                      )
                    : DevCoopTextStyle.light_30.copyWith(
                        color: DevCoopColors.black,
                      ),
          ),
        ),
        Container(
          width: 155,
          alignment: Alignment.centerRight,
          child:
              Text(rightText ?? NumberFormatUtil.convert1000Number(right ?? 0),
                  style: contentsTitle
                      ? DevCoopTextStyle.medium_30.copyWith(
                          color: DevCoopColors.black,
                        )
                      : totalText
                          ? DevCoopTextStyle.bold_30.copyWith(
                              color: DevCoopColors.black,
                            )
                          : DevCoopTextStyle.light_30.copyWith(
                              color: DevCoopColors.black,
                            )),
        ),
        const SizedBox(width: 10),
        plus.isNotEmpty
            ? Container(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      itemResponses
                          .firstWhere((element) => element.itemName == itemName)
                          .quantity += 1;
                      // 상품 추가 버튼 클릭 시 상품 갯수 증가
                      totalPrice += itemResponses
                          .firstWhere((element) => element.itemName == itemName)
                          .itemPrice;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DevCoopColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                      side: const BorderSide(
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    plus,
                    textAlign: TextAlign.center,
                    style: DevCoopTextStyle.bold_30.copyWith(
                      color: DevCoopColors.black,
                      fontSize: 30,
                    ),
                  ),
                ),
              )
            : const SizedBox(
                width: 54,
              ),
        const SizedBox(width: 10),
        plus.isNotEmpty
            ? Container(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      for (int i = 0; i < itemResponses.length; i++) {
                        if (itemResponses[i].itemName == itemName) {
                          if (itemResponses[i].quantity > 1) {
                            itemResponses[i].quantity -= 1;
                            break;
                          } else {
                            // 상품을 삭제하기 전에 가격을 임시 변수에 저장
                            var itemPrice = itemResponses[i].itemPrice;
                            itemResponses.removeAt(i);
                            // 삭제된 상품의 가격만큼 총 가격에서 빼기
                            totalPrice = (totalPrice - itemPrice) > 0
                                ? (totalPrice - itemPrice)
                                : 0;
                            break;
                          }
                        }
                      }

                      // 상품 삭제 버튼 클릭 시 상품 총 가격 감소
                      totalPrice > 0
                          ? totalPrice -= itemResponses
                              .firstWhere(
                                  (element) => element.itemName == itemName)
                              .itemPrice
                          : totalPrice = 0;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DevCoopColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                      side: const BorderSide(
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    minus,
                    textAlign: TextAlign.center,
                    style: DevCoopTextStyle.bold_30.copyWith(
                      color: DevCoopColors.black,
                      fontSize: 30,
                    ),
                  ),
                ),
              )
            : const SizedBox(
                width: 54,
              ),
      ],
    );
  }

  Future<void> handleSelfCharge() async {
    try {
      final standbyResponse = await http.post(
        Uri.parse(
            'https://occount.bsm-aripay.kr/api/v2/pg/self-charge/standby'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (standbyResponse.statusCode != 200) {
        showPaymentsPopup("충전 대기 등록에 실패했습니다.", true);
        return;
      }

      final standbyData = json.decode(utf8.decode(standbyResponse.bodyBytes));
      final String standbyToken = standbyData['standbyToken'];

      if (!mounted) return;

      bool dialogActive = true;
      final startTime = DateTime.now();
      Timer? timer;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return WillPopScope(
            onWillPop: () async => false,
            child: StatefulBuilder(
              builder: (context, setState) {
                double progress =
                    DateTime.now().difference(startTime).inSeconds / 120;

                timer?.cancel();
                timer =
                    Timer.periodic(const Duration(seconds: 1), (timer) async {
                  if (!dialogActive) {
                    timer.cancel();
                    return;
                  }

                  final elapsedSeconds =
                      DateTime.now().difference(startTime).inSeconds;
                  if (elapsedSeconds >= 120) {
                    dialogActive = false;
                    timer.cancel();
                    Navigator.pop(dialogContext);
                    showPaymentsPopup("충전 시간이 초과되었습니다.", true);
                    return;
                  }

                  setState(() {
                    progress = elapsedSeconds / 120;
                  });

                  try {
                    final statusResponse = await http.get(
                      Uri.parse(
                          'https://occount.bsm-aripay.kr/api/v2/pg/self-charge/status?standbyToken=$standbyToken'),
                      headers: {
                        'Authorization': 'Bearer $accessToken',
                      },
                    );

                    if (statusResponse.statusCode == 200) {
                      final statusData =
                          json.decode(utf8.decode(statusResponse.bodyBytes));

                      switch (statusData['status']) {
                        case 'USED':
                          dialogActive = false;
                          timer.cancel();
                          Navigator.pop(dialogContext);
                          String message = "충전이 완료되었습니다.";
                          if (statusData['chargedPoint'] != null) {
                            message += "\n충전금액: ${statusData['chargedPoint']}원";
                          }
                          if (statusData['afterPoint'] != null) {
                            message += "\n현재 잔액: ${statusData['afterPoint']}원";
                          }
                          showPaymentsPopup(message, false);
                          loadUserData();
                          break;
                        case 'EXPIRED':
                        case 'NONE':
                          dialogActive = false;
                          timer.cancel();
                          Navigator.pop(dialogContext);
                          showPaymentsPopup(
                            statusData['status'] == 'EXPIRED'
                                ? "충전 요청이 만료되었습니다."
                                : "충전 요청을 찾을 수 없습니다.",
                            true,
                          );
                          break;
                      }
                    }
                  } catch (e) {
                    dialogActive = false;
                    timer.cancel();
                    Navigator.pop(dialogContext);
                    showPaymentsPopup("충전 중 오류가 발생했습니다.", true);
                  }
                });

                return AlertDialog(
                  title: const Text(
                    "충전 대기중",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "충전이 완료될 때까지 기다려주세요\n2분 이내에 단말기에서 충전해주세요",
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: DevCoopColors.grey,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          DevCoopColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${120 - (progress * 120).toInt()}초 남음",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        dialogActive = false;
                        timer?.cancel();
                        Navigator.pop(dialogContext);
                      },
                      child: const Text(
                        "취소",
                        style: TextStyle(
                          color: DevCoopColors.error,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    } catch (e) {
      showPaymentsPopup("충전 중 오류가 발생했습니다.", true);
    }
  }
}
