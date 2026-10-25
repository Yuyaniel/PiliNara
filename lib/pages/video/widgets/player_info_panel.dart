import 'dart:async';

import 'package:media_kit/media_kit.dart' show NativePlayer;
import 'package:material_ui/material_ui.dart';

/// 播放信息侧栏
///
/// 数据取自媒体引擎属性：
/// - `video-params`：分辨率 / 色彩矩阵
/// - `video-track`：编码 / 帧率
/// - `video-bitrate` / `demuxer-cache-speed`：实时码率与下载速度（每秒刷新）
Future<void> showPlayerInfoPanel(
  BuildContext context, {
  required NativePlayer player,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '播放信息',
    barrierColor: const Color(0x33000000),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => Align(
      alignment: Alignment.centerRight,
      child: _PlayerInfoPanel(player: player),
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

/// 实时视频码率：mpv 的 `video-bitrate` 单位是 bit/s
String _formatBitrate(NativePlayer player) {
  final raw = player.getProperty('video-bitrate');
  final bps = double.tryParse(raw);
  if (bps == null || bps <= 0) return '-';
  if (bps >= 1000 * 1000) {
    return '${(bps / 1000 / 1000).toStringAsFixed(2)} Mbps';
  }
  return '${(bps / 1000).toStringAsFixed(0)} kbps';
}

/// 已缓存的时长（秒）
String _formatCacheDuration(NativePlayer player) {
  final raw = player.getProperty('demuxer-cache-duration');
  final seconds = double.tryParse(raw);
  if (seconds == null || seconds <= 0) return '-';
  return '${seconds.toStringAsFixed(1)} s';
}

class _PlayerInfoPanel extends StatefulWidget {
  const _PlayerInfoPanel({required this.player});

  final NativePlayer player;

  @override
  State<_PlayerInfoPanel> createState() => _PlayerInfoPanelState();
}

class _PlayerInfoPanelState extends State<_PlayerInfoPanel> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 码率与下载速度是实时值，每秒刷新
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.player.state;
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
      ('视频码率', _formatBitrate(widget.player)),
      ('缓存时长', _formatCacheDuration(widget.player)),
    ];

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
                      vertical: 6,
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
