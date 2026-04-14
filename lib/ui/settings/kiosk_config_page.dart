import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/kiosk_config_service.dart';
import '../_constant/theme/devcoop_colors.dart';
import '../_constant/theme/devcoop_text_style.dart';

class KioskConfigPage extends StatefulWidget {
  const KioskConfigPage({Key? key}) : super(key: key);

  @override
  State<KioskConfigPage> createState() => _KioskConfigPageState();
}

class _KioskConfigPageState extends State<KioskConfigPage> {
  final TextEditingController _kioskIdController = TextEditingController();
  String? _currentKioskId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentKioskId();
  }

  @override
  void dispose() {
    _kioskIdController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentKioskId() async {
    setState(() => _isLoading = true);
    try {
      final kioskConfigService = context.read<KioskConfigService>();
      final kioskId = await kioskConfigService.getKioskId();
      if (mounted) {
        setState(() {
          _currentKioskId = kioskId;
          _kioskIdController.text = kioskId ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('키오스크 ID를 불러오는데 실패했습니다');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveKioskId() async {
    final kioskId = _kioskIdController.text.trim();

    if (kioskId.isEmpty) {
      _showErrorSnackBar('키오스크 ID를 입력해주세요');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final kioskConfigService = context.read<KioskConfigService>();
      final success = await kioskConfigService.saveKioskId(kioskId);

      if (mounted) {
        if (success) {
          setState(() => _currentKioskId = kioskId);
          _showSuccessSnackBar('키오스크 ID가 저장되었습니다');

          // 설정 완료 후 2초 뒤에 자동으로 홈으로 이동
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            }
          });
        } else {
          _showErrorSnackBar('키오스크 ID 저장에 실패했습니다');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('키오스크 ID 저장 중 오류가 발생했습니다');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAlreadySet = _currentKioskId?.isNotEmpty == true;

    return Scaffold(
      backgroundColor: DevCoopColors.grey,
      appBar: AppBar(
        title: const Text('키오스크 설정'),
        backgroundColor: DevCoopColors.primary,
        foregroundColor: DevCoopColors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAlreadySet ? '키오스크 ID 정보' : '키오스크 ID 설정',
                    style: DevCoopTextStyle.bold_30,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAlreadySet
                        ? '이 키오스크의 고유 ID입니다.'
                        : '각 키오스크를 식별하기 위한 고유 ID를 설정합니다.',
                    style: DevCoopTextStyle.medium_20,
                  ),
                  const SizedBox(height: 32),

                  // 현재 키오스크 ID 표시
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isAlreadySet ? DevCoopColors.primary.withValues(alpha: 0.1) : DevCoopColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isAlreadySet ? DevCoopColors.primary : Colors.grey.shade300,
                        width: isAlreadySet ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isAlreadySet ? Icons.check_circle : Icons.info_outline,
                              color: isAlreadySet ? DevCoopColors.primary : Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAlreadySet ? '등록된 키오스크 ID' : '키오스크 ID 미설정',
                              style: DevCoopTextStyle.medium_20.copyWith(
                                color: isAlreadySet ? DevCoopColors.primary : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentKioskId?.isNotEmpty == true
                              ? _currentKioskId!
                              : '아직 설정되지 않았습니다',
                          style: DevCoopTextStyle.bold_30.copyWith(
                            color: _currentKioskId?.isNotEmpty == true
                                ? DevCoopColors.primary
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isAlreadySet) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock, color: Colors.blue.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '키오스크 ID는 보안을 위해 한 번 설정하면 변경할 수 없습니다.',
                              style: DevCoopTextStyle.medium_20.copyWith(
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),

                    // 키오스크 ID 입력 (미설정 상태에서만 표시)
                    Text(
                      '새 키오스크 ID',
                      style: DevCoopTextStyle.medium_20,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _kioskIdController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'KIOSK_001',
                        filled: true,
                        fillColor: DevCoopColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: DevCoopColors.primary, width: 2),
                        ),
                      ),
                      style: DevCoopTextStyle.medium_20,
                    ),

                    const SizedBox(height: 32),

                    // 등록 버튼 (미설정 상태에서만 표시)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveKioskId,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DevCoopColors.primary,
                          foregroundColor: DevCoopColors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '키오스크 ID 등록',
                          style: DevCoopTextStyle.bold_20,
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // 도움말
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DevCoopColors.primaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡 안내사항',
                          style: DevCoopTextStyle.bold_20.copyWith(
                            color: DevCoopColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAlreadySet
                              ? '• 키오스크 ID는 주문 시 백엔드로 전송됩니다.\n'
                                '• 보안상 한 번 설정하면 변경이 불가능합니다.\n'
                                '• 변경이 필요한 경우 관리자에게 문의하세요.'
                              : '• 키오스크 ID는 주문 요청 시 백엔드로 함께 전송됩니다.\n'
                                '• 각 키오스크마다 고유한 ID를 설정해주세요.\n'
                                '• 예: KIOSK_001, KIOSK_A, TABLET_01 등\n'
                                '• 한 번 설정하면 변경할 수 없으니 신중히 입력하세요.',
                          style: DevCoopTextStyle.medium_20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}