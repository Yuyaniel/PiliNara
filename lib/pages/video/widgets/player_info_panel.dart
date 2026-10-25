import 'package:media_kit/media_kit.dart' show NativePlayer;
import 'package:material_ui/material_ui.dart';

/// 播放信息侧栏
///
/// 数据全部取自媒体引擎的 `video-params`（分辨率 / 色彩矩阵）与
/// `video-track`（编码 / 帧率），与「更多 → 播放信息」同源。
Future<void> showPlayerInfoPanel(
  BuildContext context, {
  required NativePlayer player,
}) {
  final state = player.state;
  final params = state.videoParams;
  final video = state.track.video;

  final width = params.w ?? video.w;
  final height = params.h ?? video.h;
  final fps = video.fps;

  final rows = <(String, String)>[
    ('编码', _nonEmpty(video.codec)),
    (
      '分辨率',
      width != null && height != null && width > 0 && height > 0
          ? '${width}x$height'
          : '-',
    ),
    ('帧率', fps == null ? '-' : fps.toStringAsFixed(1)),
    ('色彩矩阵', _nonEmpty(params.colormatrix)),
  ];

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '播放信息',
    barrierColor: const Color(0x33000000),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => Align(
      alignment: Alignment.centerRight,
      child: _PlayerInfoPanel(rows: rows),
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

String _nonEmpty(String? value) {
  if (value == null || value.isEmpty) return '-';
  return value;
}

class _PlayerInfoPanel extends StatelessWidget {
  const _PlayerInfoPanel({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.82),
      child: SizedBox(
        width: 216,
        height: MediaQuery.sizeOf(context).height,
        child: SafeArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Text(
                    '播放信息',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                for (final (label, value) in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
