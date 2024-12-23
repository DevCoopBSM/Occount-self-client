import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../_constant/component/button.dart';
import '../_constant/theme/devcoop_text_style.dart';
import '../_constant/theme/devcoop_colors.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';

class BarcodeScanPage extends StatefulWidget {
  const BarcodeScanPage({Key? key}) : super(key: key);

  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage>
    with WidgetsBindingObserver {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _codeNumberController = TextEditingController();
  final FocusNode _barcodeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _codeNumberController = TextEditingController(text: '');

    // 화면 진입 시 로그인 상태가 아닐 때만 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (!authProvider.isLoggedIn) {
          _refreshContent();
        }
      }
    });
  }

  @override
  void dispose() {
    _codeNumberController.dispose();
    _barcodeFocus.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _refreshContent() {
    if (!mounted) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        _codeNumberController.text = '';
        FocusScope.of(context).requestFocus(_barcodeFocus);
      });
    });
  }

  Future<void> handleScan() async {
    if (!mounted) return;

    setState(() {
      // 상태 업데이트
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) => Scaffold(
        body: PopScope(
          onPopInvoked: (bool didPop) async {
            FocusScope.of(context).requestFocus(_barcodeFocus);
          },
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 30, horizontal: 90),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "학생증의 바코드를\n리더기로 스캔해주세요.",
                        style: DevCoopTextStyle.bold_40.copyWith(
                          color: DevCoopColors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 0.2.sh),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '학생증 번호',
                                style: DevCoopTextStyle.medium_30.copyWith(
                                  color: DevCoopColors.black,
                                ),
                              ),
                              const SizedBox(width: 40),
                              Container(
                                alignment: Alignment.center,
                                width: 500,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 34, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECECEC),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: TextFormField(
                                  controller: _codeNumberController,
                                  focusNode: _barcodeFocus,
                                  onFieldSubmitted: (value) {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      if (!mounted) return;
                                      Navigator.pushNamed(
                                        context,
                                        '/pin',
                                        arguments: _codeNumberController.text,
                                      );
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '학생증 번호를 입력해주세요.';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                    hintText: '학생증을 리더기에 스캔해주세요',
                                    hintStyle: DevCoopTextStyle.medium_30
                                        .copyWith(fontSize: 15),
                                    border: InputBorder.none,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 60),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              mainTextButton(
                                text: '다음으로',
                                onTap: () {
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    if (!mounted) return;
                                    Navigator.pushNamed(
                                      context,
                                      '/pin',
                                      arguments: _codeNumberController.text,
                                    );
                                  }
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
