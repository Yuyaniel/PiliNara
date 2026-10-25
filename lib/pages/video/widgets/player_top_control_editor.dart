import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_ui/material_ui.dart';

/// 全屏右上角操作控件的显隐配置
abstract final class PlayerTopControls {
  static const String like = 'like';
  static const String coin = 'coin';
  static const String fav = 'fav';
  static const String download = 'download';
  static const String info = 'info';
  static const String share = 'share';

  /// id -> (显示名, 图标)
  static const Map<String, (String, IconData)> meta = {
    like: ('点赞', FontAwesomeIcons.thumbsUp),
    coin: ('投币', FontAwesomeIcons.b),
    fav: ('收藏', FontAwesomeIcons.star),
    download: ('缓存', CustomIcons.download),
    info: ('播放信息', Icons.info_outline),
    share: ('分享', FontAwesomeIcons.shareFromSquare),
  };

  static bool isEnabled(String id) => Pref.playerTopControls.contains(id);

  /// 打开控件编辑面板，保存后回调刷新
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onChanged,
  }) async {
    final enabled = Set<String>.from(
      Pref.playerTopControls.where(meta.containsKey),
    );
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.tune, size: 18),
              SizedBox(width: 8),
              Text('控件编辑'),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          content: SizedBox(
            width: 330,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 16,
              children: [
                for (final entry in meta.entries)
                  _ControlChip(
                    icon: entry.value.$2,
                    label: entry.value.$1,
                    enabled: enabled.contains(entry.key),
                    onTap: () => setLocalState(() {
                      if (!enabled.remove(entry.key)) {
                        enabled.add(entry.key);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, enabled),
              child: const Text('完成编辑'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      await GStorage.setting.put(
        SettingBoxKey.playerTopControls,
        result.toList(),
      );
      onChanged();
    }
  }
}

const Color _kActive = Color(0xFFFE6699);

class _ControlChip extends StatelessWidget {
  const _ControlChip({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = enabled ? _kActive : colorScheme.outline;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            painter: _DashedBorderPainter(
              color: color,
              radius: 8,
              dashWidth: 4,
              dashGap: 3,
            ),
            child: SizedBox(
              width: 92,
              height: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: color),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ],
              ),
            ),
          ),
          if (enabled)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: _kActive,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    this.radius = 8,
    this.dashWidth = 4,
    this.dashGap = 3,
  });

  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;
  static const double strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashGap != dashGap;
}
