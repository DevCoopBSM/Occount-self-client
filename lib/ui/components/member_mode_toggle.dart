import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../provider/auth_provider.dart';
import '../../utils/sound_utils.dart';
import '../_constant/theme/devcoop_colors.dart';
import '../_constant/theme/devcoop_text_style.dart';

const Duration _indicatorDuration = Duration(milliseconds: 220);
const Duration _curtainInDuration = Duration(milliseconds: 180);
const Duration _curtainOutDuration = Duration(milliseconds: 280);
const double _segmentWidth = 110;
const double _segmentHeight = 46;

/// 화면 왼쪽 하단에 띄우는 회원/비회원 전환 토글.
/// 탭하면 하이라이트가 미끄러진 뒤, 배경색 커튼으로 화면을 덮은 상태에서 모드를 바꾸고
/// 루트로 이동해 main.dart의 '/' 라우트가 모드에 맞는 화면을 다시 고르게 한다.
/// (덮지 않고 교체하면 이전 화면이 바뀐 모드로 잠깐 다시 그려지는 게 보인다)
class MemberModeToggle extends StatefulWidget {
  const MemberModeToggle({Key? key}) : super(key: key);

  @override
  State<MemberModeToggle> createState() => _MemberModeToggleState();
}

class _MemberModeToggleState extends State<MemberModeToggle> {
  // 전환 중 중복 탭 방지 (전환 도중 토글이 새 화면의 것으로 교체되므로 static)
  static bool _isSwitching = false;
  bool? _pendingGuest;

  Future<void> _switchMode({required bool toGuest}) async {
    final authProvider = context.read<AuthProvider>();
    if (_isSwitching || authProvider.isGuestMode == toGuest) return;
    _isSwitching = true;

    SoundUtils.playSound(SoundType.click);
    setState(() => _pendingGuest = toGuest);

    final overlay = globalNavigatorKey.currentState?.overlay;
    final curtainColor = Theme.of(context).scaffoldBackgroundColor;
    final curtainVisible = ValueNotifier<bool>(false);
    final curtain = OverlayEntry(
      builder: (_) => _ModeSwitchCurtain(
        visible: curtainVisible,
        color: curtainColor,
      ),
    );

    try {
      await Future.delayed(_indicatorDuration);

      if (overlay != null) {
        overlay.insert(curtain);
        await WidgetsBinding.instance.endOfFrame;
        curtainVisible.value = true;
        await Future.delayed(_curtainInDuration);
      }

      if (toGuest) {
        authProvider.enableGuestMode();
      } else {
        authProvider.switchToMemberMode();
      }
      globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );

      if (overlay != null) {
        await WidgetsBinding.instance.endOfFrame;
        curtainVisible.value = false;
        await Future.delayed(_curtainOutDuration);
      }
    } finally {
      if (curtain.mounted) curtain.remove();
      curtainVisible.dispose();
      _isSwitching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuestMode = _pendingGuest ??
        context.select<AuthProvider, bool>((p) => p.isGuestMode);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DevCoopColors.grey,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        width: _segmentWidth * 2,
        height: _segmentHeight,
        child: Stack(
          children: [
            AnimatedAlign(
              alignment:
                  isGuestMode ? Alignment.centerRight : Alignment.centerLeft,
              duration: _indicatorDuration,
              curve: Curves.easeOutCubic,
              child: Container(
                width: _segmentWidth,
                height: _segmentHeight,
                decoration: BoxDecoration(
                  color: DevCoopColors.primary,
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
            Row(
              children: [
                _ModeSegment(
                  label: '회원',
                  icon: Icons.badge,
                  isSelected: !isGuestMode,
                  onTap: () => _switchMode(toGuest: false),
                ),
                _ModeSegment(
                  label: '비회원',
                  icon: Icons.person_outline,
                  isSelected: isGuestMode,
                  onTap: () => _switchMode(toGuest: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeSegment({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: _segmentWidth,
        height: _segmentHeight,
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(
            end: isSelected ? DevCoopColors.black : Colors.grey.shade600,
          ),
          duration: _indicatorDuration,
          builder: (context, color, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: DevCoopTextStyle.bold_20.copyWith(
                  fontSize: 18,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 모드 전환 동안 화면 전체를 덮는 페이드 커튼. 전환 중 입력도 막는다.
class _ModeSwitchCurtain extends StatelessWidget {
  final ValueNotifier<bool> visible;
  final Color color;

  const _ModeSwitchCurtain({required this.visible, required this.color});

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: ValueListenableBuilder<bool>(
        valueListenable: visible,
        builder: (context, isVisible, _) => AnimatedOpacity(
          opacity: isVisible ? 1 : 0,
          duration: isVisible ? _curtainInDuration : _curtainOutDuration,
          curve: Curves.easeInOut,
          child: ColoredBox(color: color, child: const SizedBox.expand()),
        ),
      ),
    );
  }
}
