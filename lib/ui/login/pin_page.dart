import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import '../_constant/component/button.dart';
import '../_constant/theme/devcoop_text_style.dart';
import '../_constant/theme/devcoop_colors.dart';

class PinPage extends StatefulWidget {
  const PinPage({Key? key}) : super(key: key);

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  String? _userCode;
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocus = FocusNode();

  void onNumberButtonPressed(int number, TextEditingController controller) {
    if (controller.text.length < 6) {
      controller.text = controller.text + number.toString();
    }
  }

  void onClearPressed(TextEditingController controller) {
    controller.clear();
  }

  void onDeletePressed(TextEditingController controller) {
    if (controller.text.isNotEmpty) {
      controller.text =
          controller.text.substring(0, controller.text.length - 1);
    }
  }

  Future<void> _handleSubmit() async {
    if (_userCode == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 코드가 없습니다')),
      );
      Navigator.of(context).pushReplacementNamed('/scan');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final pin = _pinController.text;

    if (pin.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('핀 번호를 입력해주세요')),
      );
      return;
    }

    try {
      final result = await authProvider.login(_userCode!, pin);

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${authProvider.userInfo.userName}님 환영합니다'),
            duration: const Duration(milliseconds: 500),
          ),
        );
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/payment', (route) => false);
      } else if (result.redirectUrl != null) {
        Navigator.of(context).pushReplacementNamed(
          '/pin/change',
          arguments: {'redirectUrl': result.redirectUrl},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? '로그인에 실패했습니다')),
        );
        _pinController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      _pinController.clear();
    }
  }

  void _setActiveController(TextEditingController controller) {
    FocusScope.of(context).requestFocus(_pinFocus);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is String) {
        setState(() {
          _userCode = args;
        });
        Future.microtask(() {
          if (mounted) {
            FocusScope.of(context).requestFocus(_pinFocus);
          }
        });
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
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
              const SizedBox(
                height: 90,
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        for (int i = 0; i < 3; i++) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (int j = 0; j < 3; j++) ...[
                                pinButton(
                                  text: (i * 3 + j + 1).toString(),
                                  onTap: () => onNumberButtonPressed(
                                    i * 3 + j + 1,
                                    _pinController,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              width: 80,
                              child: specialPinButton(
                                text: 'Clear',
                                onTap: () => onClearPressed(_pinController),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: pinButton(
                                text: '0',
                                onTap: () =>
                                    onNumberButtonPressed(0, _pinController),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: specialPinButton(
                                text: 'Del',
                                onTap: () => onDeletePressed(_pinController),
                              ),
                            ),
                          ],
                        ),
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
                                '핀 번호',
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
                                    controller: _pinController,
                                    focusNode: _pinFocus,
                                    textAlign: TextAlign.center,
                                    style: DevCoopTextStyle.bold_30.copyWith(
                                      color: DevCoopColors.black,
                                      fontSize: 24,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '핀 번호를 입력해주세요';
                                      }
                                      return null;
                                    },
                                    onFieldSubmitted: (value) {
                                      _handleSubmit();
                                    },
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                      hintText: '자신의 핀번호를 입력해주세요',
                                      hintStyle:
                                          DevCoopTextStyle.medium_30.copyWith(
                                        fontSize: 15,
                                        color: DevCoopColors.black
                                            .withOpacity(0.5),
                                      ),
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
                          height: 60,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            mainTextButton(
                              text: '처음으로',
                              onTap: () {
                                Navigator.of(context).pushReplacementNamed('/');
                              },
                            ),
                            mainTextButton(
                              text: '확인',
                              onTap: () {
                                _handleSubmit();
                              },
                            ),
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
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }
}
