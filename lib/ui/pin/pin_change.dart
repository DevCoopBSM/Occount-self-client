import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../_constant/component/button.dart';
import '../_constant/theme/devcoop_text_style.dart';
import '../_constant/theme/devcoop_colors.dart';
import '../../provider/pin_change_provider.dart';

class PinChange extends StatefulWidget {
  const PinChange({Key? key}) : super(key: key);

  @override
  State<PinChange> createState() => _PinChangeState();
}

class _PinChangeState extends State<PinChange> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();

  final FocusNode _idFocus = FocusNode();
  final FocusNode _pinFocus = FocusNode();
  final FocusNode _newPinFocus = FocusNode();

  TextEditingController _activeController = TextEditingController();

  void _setActiveController(TextEditingController controller) {
    setState(() {
      _activeController = controller;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_idFocus);
    });
  }

  void onNumberButtonPressed(int number) {
    String currentText = _activeController.text;

    if (number == 10) {
      _activeController.clear();
    } else if (number == 12) {
      if (currentText.isNotEmpty) {
        String newText = currentText.substring(0, currentText.length - 1);
        _activeController.text = newText;
      }
    } else {
      String newText = currentText + (number == 11 ? '0' : number.toString());
      _activeController.text = newText;
    }
  }

  void _handlePinChange() {
    final pinChangeProvider =
        Provider.of<PinChangeProvider>(context, listen: false);

    if (_idController.text.isEmpty ||
        _pinController.text.isEmpty ||
        _newPinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력해주세요')),
      );
      return;
    }

    pinChangeProvider
        .changePinNumber(
      _idController.text,
      _pinController.text,
      _newPinController.text,
      context,
    )
        .then((success) {
      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    });
  }

  @override
  void dispose() {
    _activeController.dispose();
    _idController.dispose();
    _pinController.dispose();
    _newPinController.dispose();
    _idFocus.dispose();
    _pinFocus.dispose();
    _newPinFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) => Scaffold(
        body: Container(
          margin: const EdgeInsets.symmetric(
            vertical: 30,
            horizontal: 90,
          ),
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  "핀 번호를 입력해주세요",
                  style: DevCoopTextStyle.bold_40.copyWith(
                    color: DevCoopColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 0.01.sh,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          for (int i = 0; i < 4; i++) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (int j = 0; j < 3; j++) ...[
                                  GestureDetector(
                                    onTap: () {
                                      int number = j + 1 + i * 3;
                                      onNumberButtonPressed(
                                          number == 11 ? 0 : number);
                                    },
                                    child: Container(
                                      width: 95,
                                      height: 95,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: (j + 1 + i * 3 == 10 ||
                                                j + 1 + i * 3 == 12)
                                            ? DevCoopColors.primary
                                            : const Color(0xFFD9D9D9),
                                      ),
                                      child: Text(
                                        '${j + 1 + i * 3 == 10 ? 'Clear' : (j + 1 + i * 3 == 11 ? '0' : (j + 1 + i * 3 == 12 ? 'Del' : j + 1 + i * 3))}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          color: DevCoopColors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (i < 3) ...[
                              const SizedBox(
                                height: 10,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 160,
                                child: Text(
                                  '학생증 번호',
                                  style: DevCoopTextStyle.medium_30.copyWith(
                                    color: DevCoopColors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    _setActiveController(_idController);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 34,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECECEC),
                                      borderRadius: BorderRadius.circular(
                                        20,
                                      ),
                                    ),
                                    child: TextFormField(
                                      // 엔터 입력되면 focus를 다음으로 넘기기
                                      onFieldSubmitted: ((value) => {
                                            // 현재 포커스는 지우고
                                            // 다음 포커스로 이동
                                            FocusScope.of(context)
                                                .requestFocus(_pinFocus)
                                          }),
                                      // TextField 대신 TextFormField을 사용합니다.
                                      controller: _idController,
                                      focusNode: _idFocus,
                                      validator: (value) {
                                        // 여기에 validator 추가
                                        if (value == null || value.isEmpty) {
                                          return '학생증번호를 입력해주세요';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.zero,
                                        isDense: true,
                                        hintText: '학생증번호를 입력해주세요',
                                        hintStyle: DevCoopTextStyle.medium_30
                                            .copyWith(fontSize: 15),
                                        border: InputBorder.none,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 160,
                                child: Text(
                                  '현재 핀번호',
                                  style: DevCoopTextStyle.medium_30.copyWith(
                                    color: DevCoopColors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    _setActiveController(_pinController);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 34,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECECEC),
                                      borderRadius: BorderRadius.circular(
                                        20,
                                      ),
                                    ),
                                    child: TextFormField(
                                      obscureText: true,
                                      // TextField 대신 TextFormField을 사용합니다.
                                      controller: _pinController,
                                      focusNode: _pinFocus,
                                      validator: (value) {
                                        // 여기에 validator 추가
                                        if (value == null || value.isEmpty) {
                                          return '핀 번호를 입력해주세요';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.zero,
                                        isDense: true,
                                        hintText: '자신의 핀번호를 입력해주세요',
                                        hintStyle: DevCoopTextStyle.medium_30
                                            .copyWith(fontSize: 15),
                                        border: InputBorder.none,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 160,
                                child: Text(
                                  '바꿀 핀번호',
                                  style: DevCoopTextStyle.medium_30.copyWith(
                                    color: DevCoopColors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    _setActiveController(_newPinController);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 34,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECECEC),
                                      borderRadius: BorderRadius.circular(
                                        20,
                                      ),
                                    ),
                                    child: TextFormField(
                                      obscureText: true,
                                      // TextField 대신 TextFormField을 사용합니다.
                                      controller: _newPinController,
                                      focusNode: _newPinFocus,
                                      validator: (value) {
                                        // 여기에 validator 추가
                                        if (value == null || value.isEmpty) {
                                          return '핀 번호를 입력해주세요';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.zero,
                                        isDense: true,
                                        hintText: '자신의 핀번호를 입력해주세요',
                                        hintStyle: DevCoopTextStyle.medium_30
                                            .copyWith(fontSize: 15),
                                        border: InputBorder.none,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 50,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              mainTextButton(
                                text: '처음으로',
                                onTap: () {
                                  Navigator.of(context)
                                      .pushReplacementNamed('/');
                                },
                              ),
                              mainTextButton(
                                text: '다음으로',
                                onTap: () {
                                  _handlePinChange();
                                },
                              ),
                              // 서버에서 response 받은 에러메세지 출력
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
