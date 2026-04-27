import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
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
  static const Duration _prefetchDebounce = Duration(milliseconds: 150);

  String? _userCode;
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocus = FocusNode();
  Timer? _prefetchDebounceTimer;

  void _restorePinFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_pinFocus);
    });
  }

  void _handlePinChanged() {
    final userCode = _userCode;
    if (userCode == null) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final pin = _pinController.text;

    _prefetchDebounceTimer?.cancel();

    if (pin.length >= 4 && pin.length <= 6) {
      _prefetchDebounceTimer = Timer(_prefetchDebounce, () {
        if (!mounted) {
          return;
        }

        authProvider.prefetchLogin(userCode, pin);
      });
      return;
    }

    authProvider.clearPrefetchedLogin();
  }

  void onNumberButtonPressed(int number, TextEditingController controller) {
    if (controller.text.length < 6) {
      controller.text = controller.text + number.toString();
    }

    _restorePinFocus();
  }

  void onClearPressed(TextEditingController controller) {
    controller.clear();
    _restorePinFocus();
  }

  void onDeletePressed(TextEditingController controller) {
    if (controller.text.isNotEmpty) {
      controller.text =
          controller.text.substring(0, controller.text.length - 1);
    }

    _restorePinFocus();
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

    if (pin.length < 4 || pin.length > 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('핀 번호는 4자리 이상 6자리 이하로 입력해주세요')),
      );
      return;
    }

    try {
      final result = await authProvider.login(_userCode!, pin);

      if (!mounted) return;

      if (result.success) {
        rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/payment', (route) => false);
      } else {
        if (authProvider.error == 'DEFAULT_PIN_IN_USE') {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text(
                '초기 비밀번호 변경 안내',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              content: const SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '보안을 위해 초기 비밀번호를 변경해주세요.\n\n'
                      '1. 관리자에게 문의하여 웹사이트에 접속\n'
                      '2. 로그인 후 [햄버거] 버튼 누르고 개인정보변경으로 이동\n'
                      '3. [핀번호 변경하기] 버튼을 클릭하여 변경\n\n'
                      '* 키오스크에서는 핀번호를 변경할 수 없습니다.',
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/'),
                  child: const Text(
                    '처음으로',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? '로그인에 실패했습니다')),
          );
        }
      }
      _pinController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      _pinController.clear();
    }
  }

  void _setActiveController(TextEditingController controller) {
    _restorePinFocus();
  }

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_handlePinChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is String) {
        setState(() {
          _userCode = args;
        });
        Future.microtask(_restorePinFocus);
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                                    autofocus: true,
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
                                      if (value.length < 4 ||
                                          value.length > 6) {
                                        return '핀 번호는 4자리 이상 6자리 이하로 입력해주세요';
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
                                            .withValues(alpha: 0.5),
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
    _prefetchDebounceTimer?.cancel();
    Provider.of<AuthProvider>(context, listen: false).clearPrefetchedLogin();
    _pinController.removeListener(_handlePinChanged);
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }
}
