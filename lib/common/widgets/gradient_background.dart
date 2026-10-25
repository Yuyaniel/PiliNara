import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:material_ui/material_ui.dart';

/// 与主布局（`pages/main/view.dart`）一致的渐变背景层。
///
/// 主布局把它铺在 `Stack` 底层，让各页面用透明 Scaffold 透出来；
/// 新开的路由（如 UP 动态全屏页）因为 `PageRoute.opaque` 不会绘制下层路由，
/// 需要自己再铺一层同样的渐变，视觉才与主界面一致。
class GradientLayer extends StatelessWidget {
  const GradientLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Opacity(
      opacity: .6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: .6),
              colorScheme.primaryContainer.withValues(alpha: .6),
              colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [.1, .4, .7],
          ),
        ),
      ),
    );
  }
}

/// 便捷包装：在 [child] 底层铺渐变，并跟随 `Pref.enableGradientBg` 开关。
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Pref.enableGradientBg) return child;
    return Stack(
      children: [const Positioned.fill(child: GradientLayer()), child],
    );
  }
}
