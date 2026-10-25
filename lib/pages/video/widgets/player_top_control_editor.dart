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

  static Set<String> current() =>
      Pref.playerTopControls.where(meta.containsKey).toSet();

  static Future<void> save(Set<String> ids) => GStorage.setting.put(
    SettingBoxKey.playerTopControls,
    ids.toList(),
  );
}

const Color _kActive = Color(0xFFFE6699);

/// 编辑态下的单个控件：虚线圆角框 + 右上角勾选角标，点击切换
class PlayerTopControlChip extends StatelessWidget {
  const PlayerTopControlChip({
    super.key,
    required this.id,
    required this.enabled,
    required this.onTap,
  });

  final String id;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = PlayerTopControls.meta[id]!;
    final color = enabled ? _kActive : Colors.white70;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            painter: _DashedBorderPainter(
              color: enabled ? _kActive : Colors.white38,
              radius: 8,
              dashWidth: 4,
              dashGap: 3,
            ),
            child: SizedBox(
              width: 52,
              height: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(meta.$2, size: 16, color: color),
                  const SizedBox(height: 2),
                  Text(
                    meta.$1,
                    style: TextStyle(fontSize: 8, color: color),
                  ),
                ],
              ),
            ),
          ),
          if (enabled)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                  color: _kActive,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 9, color: Colors.white),
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
