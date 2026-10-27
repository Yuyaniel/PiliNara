import 'package:PiliPlus/common/widgets/gradient_background.dart';
import 'package:PiliPlus/pages/dynamics/controller.dart';
import 'package:PiliPlus/pages/dynamics/widgets/up_feed_pager.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 单个 UP 的动态全屏页
///
/// 页内左右滑动可切换其他 UP，关闭后回到动态页原状态。
class UpDynamicsPage extends StatelessWidget {
  const UpDynamicsPage({super.key, required this.initialMid});

  final int initialMid;

  @override
  Widget build(BuildContext context) {
    final controller = Get.putOrFind(DynamicsController.new);
    // 同步选中态：头像高亮 + 已读标记
    controller.hostMid = initialMid;
    controller.currentMid = initialMid;
    controller.markUpRead(initialMid);

    // 用不透明底色兜底：渐变背景关闭时 GradientBackground 只返回 child，
    // 若 Scaffold 透明会透出下层页面（平板布局下会看到首页内容）
    return Scaffold(
      backgroundColor: ColorScheme.of(context).surface,
      body: GradientBackground(
        child: SafeArea(
        child: Column(
          children: [
            // 顶部 UP 头像栏（与关注动态页一致）
            UpAvatarStrip(
              dynamicsController: controller,
              onSelect: (mid) {
                controller.hostMid = mid;
                controller.currentMid = mid;
                controller.markUpRead(mid);
              },
            ),
            Expanded(
              child: DynamicsUpPager(
                dynamicsController: controller,
                onClose: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
