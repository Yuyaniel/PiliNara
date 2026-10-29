import 'package:PiliPlus/pages/common/multi_select/base.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class MultiSelectAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final MultiSelectBase ctr;
  final bool? visible;
  final AppBar child;
  final List<Widget>? actions;

  /// 多选栏自身的背景色；null 时沿用主题默认。
  /// 嵌入式页面（如底栏「历史」）传 Colors.transparent 以透出宿主渐变背景。
  final Color? backgroundColor;

  const MultiSelectAppBarWidget({
    super.key,
    required this.ctr,
    this.visible,
    this.actions,
    this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (visible ?? ctr.enableMultiSelect.value) {
      final style = TextButton.styleFrom(visualDensity: VisualDensity.compact);
      final colorScheme = ColorScheme.of(context);
      return AppBar(
        bottom: child.bottom,
        backgroundColor: backgroundColor,
        surfaceTintColor: backgroundColor,
        leading: IconButton(
          tooltip: '取消',
          onPressed: ctr.handleSelect,
          icon: const Icon(Icons.close_outlined),
        ),
        title: Obx(() => Text('已选: ${ctr.checkedCount}')),
        actions: [
          TextButton(
            style: style,
            onPressed: () => ctr.handleSelect(checked: true),
            child: const Text('全选'),
          ),
          ...?actions,
          TextButton(
            style: style,
            onPressed: () {
              if (ctr.checkedCount == 0) return;
              ctr.onRemove();
            },
            child: Text(
              '移除',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
          const SizedBox(width: 6),
        ],
      );
    }
    return child;
  }

  @override
  Size get preferredSize => child.preferredSize;
}
