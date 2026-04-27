import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../_constant/component/button.dart';
import '../_constant/theme/devcoop_text_style.dart';
import '../_constant/theme/devcoop_colors.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import '../../services/kiosk_config_service.dart';
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
  bool _guestModeEnabled = false;

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
        _loadGuestModeSetting();
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

  Future<void> _loadGuestModeSetting() async {
    final kioskConfigService = context.read<KioskConfigService>();
    final enabled = await kioskConfigService.isGuestModeEnabled();
    if (mounted) {
      setState(() => _guestModeEnabled = enabled);
    }
  }

  void _handleSubmit() {
    if (!mounted) return;
    final input = _codeNumberController.text.trim();

    if (input.toUpperCase() == 'ADMIN') {
      _codeNumberController.clear();
      Navigator.pushNamed(context, '/admin');
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pushNamed(context, '/pin', arguments: input);
    }
  }

  Future<void> handleScan() async {
    if (!mounted) return;

    setState(() {
      // 상태 업데이트
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PopScope(
          onPopInvokedWithResult: (bool didPop, Object? result) async {
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
                      SizedBox(height: 0.1.sh),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 라벨을 상단에 배치
                          Text(
                            '학생증 번호',
                            style: DevCoopTextStyle.medium_30.copyWith(
                              color: DevCoopColors.black,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // 입력 필드를 하단에 배치
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
                                  onFieldSubmitted: (_) => _handleSubmit(),
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
                          const SizedBox(height: 60),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                mainTextButton(
                                  text: '로그인',
                                onTap: _handleSubmit,
                              ),
                              if (_guestModeEnabled) ...[
                                const SizedBox(width: 40),
                                mainTextButton(
                                  text: '비회원',
                                  onTap: () {
                                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                    authProvider.enableGuestMode();

                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted) {
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          '/',
                                          (route) => false,
                                        );
                                      }
                                    });
                                  },
                                ),
                              ],
                            ],
                          )
                        ],
                      ),
                    ],
                  )
                ),
              )
            ),
          ),
        ),
       );
  }
}
