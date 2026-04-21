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
  bool _guestModeEnabled = false;
  bool _isEditingKioskId = false;

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
      final guestMode = await kioskConfigService.isGuestModeEnabled();
      if (mounted) {
        setState(() {
          _currentKioskId = kioskId;
          _kioskIdController.text = kioskId ?? '';
          _guestModeEnabled = guestMode;
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
          final wasEditing = _isEditingKioskId;
          setState(() {
            _currentKioskId = kioskId;
            _isEditingKioskId = false;
          });
          _showSuccessSnackBar('키오스크 ID가 저장되었습니다');

          if (!wasEditing) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            });
          }
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

                  if (isAlreadySet && !_isEditingKioskId) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEditingKioskId = true;
                            _kioskIdController.text = _currentKioskId ?? '';
                          });
                        },
                        icon: const Icon(Icons.edit),
                        label: Text(
                          '키오스크 ID 변경',
                          style: DevCoopTextStyle.bold_20,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: DevCoopColors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),

                    Text(
                      isAlreadySet ? '키오스크 ID 변경' : '새 키오스크 ID',
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

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        if (_isEditingKioskId) ...[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditingKioskId = false;
                                  _kioskIdController.text = _currentKioskId ?? '';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                                foregroundColor: DevCoopColors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('취소', style: DevCoopTextStyle.bold_20),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
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
                              isAlreadySet ? '키오스크 ID 변경 저장' : '키오스크 ID 등록',
                              style: DevCoopTextStyle.bold_20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // 비회원 모드 설정
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: DevCoopColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '비회원 결제 모드',
                                style: DevCoopTextStyle.bold_20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '활성화하면 로그인 화면에 비회원 결제 버튼이 표시됩니다.',
                                style: DevCoopTextStyle.medium_20.copyWith(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _guestModeEnabled,
                          activeColor: DevCoopColors.primary,
                          onChanged: (value) async {
                            final kioskConfigService = context.read<KioskConfigService>();
                            final success = await kioskConfigService.setGuestModeEnabled(value);
                            if (success && mounted) {
                              setState(() => _guestModeEnabled = value);
                              _showSuccessSnackBar(
                                value ? '비회원 모드가 활성화되었습니다' : '비회원 모드가 비활성화되었습니다',
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

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
                                '• 관리자 페이지에서 키오스크 ID를 변경할 수 있습니다.\n'
                                '• 비회원 모드를 활성화하면 로그인 화면에 비회원 버튼이 표시됩니다.'
                              : '• 키오스크 ID는 주문 요청 시 백엔드로 함께 전송됩니다.\n'
                                '• 각 키오스크마다 고유한 ID를 설정해주세요.\n'
                                '• 예: KIOSK_001, KIOSK_A, TABLET_01 등',
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