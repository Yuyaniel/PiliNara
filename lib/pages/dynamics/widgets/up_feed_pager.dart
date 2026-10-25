import 'package:flutter/gestures.dart';

import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/dynamics.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/dynamic/dynamics_type.dart';
import 'package:PiliPlus/models/dynamics/result.dart' hide Badge;
import 'package:PiliPlus/models/dynamics/up.dart';
import 'package:PiliPlus/pages/dynamics/controller.dart';
import 'package:PiliPlus/pages/dynamics/widgets/dynamic_panel.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' hide RefreshIndicatorState;

/// 全屏页顶部的 UP 头像栏：点击切换 UP，选中项显示箭头与高亮
class UpAvatarStrip extends StatefulWidget {
  const UpAvatarStrip({
    super.key,
    required this.dynamicsController,
    required this.onSelect,
  });

  final DynamicsController dynamicsController;
  final ValueChanged<int> onSelect;

  @override
  State<UpAvatarStrip> createState() => _UpAvatarStripState();
}

class _UpAvatarStripState extends State<UpAvatarStrip> {
  final Map<int, GlobalKey> _keys = {};
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    _worker = ever(widget.dynamicsController.currentMidRx, (mid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[mid]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.dynamicsController;
    return Obx(() {
      final state = controller.loadingState.value;
      final upList = state is Success<FollowUpModel>
          ? (state.response.upList?.where((e) => e.mid != -1).toList() ??
                const <UpItem>[])
          : const <UpItem>[];
      if (upList.isEmpty) return const SizedBox.shrink();
      final currentMid = controller.currentMid;
      return SizedBox(
        height: 78,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: upList.length,
          itemBuilder: (context, index) {
            final item = upList[index];
            final isCurrent = item.mid == currentMid;
            return SizedBox(
              key: _keys.putIfAbsent(item.mid, GlobalKey.new),
              width: 70,
              child: InkWell(
                onTap: () => widget.onSelect(item.mid),
                child: Opacity(
                  opacity: isCurrent ? 1 : 0.6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          NetworkImgLayer(
                            width: 38,
                            height: 38,
                            src: item.face,
                            type: .avatar,
                          ),
                          if (item.hasUpdate ?? false)
                            Positioned(
                              right: 2,
                              bottom: 0,
                              child: Badge(
                                smallSize: 8,
                                backgroundColor: theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.uname ?? '',
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.1,
                          color: isCurrent
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                      ),
                      if (isCurrent)
                        Icon(
                          Icons.arrow_drop_up,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

/// UP 动态分页器
///
/// 与顶部头像行共用 [DynamicsController.currentMid] 作为唯一选中态：
/// - 点头像 → [DynamicsController.onSelectUp] → currentMid 变化 → 本组件跟随翻页
/// - 左右滑动 → [DynamicsController.onSwipeUp] → currentMid 变化 → 头像行高亮跟随
class DynamicsUpPager extends StatefulWidget {
  const DynamicsUpPager({
    super.key,
    required this.dynamicsController,
    this.onClose,
  });

  final DynamicsController dynamicsController;

  /// 关闭回调：全屏页里传 pop，内嵌模式默认退出 UP 模式
  final VoidCallback? onClose;

  @override
  State<DynamicsUpPager> createState() => _DynamicsUpPagerState();
}

class _DynamicsUpPagerState extends State<DynamicsUpPager> {
  PageController? _pageController;
  Worker? _midWorker;
  List<UpItem> _upList = const [];

  DynamicsController get _controller => widget.dynamicsController;

  @override
  void initState() {
    super.initState();
    // 头像行切换时同步翻页
    _midWorker = ever(_controller.currentMidRx, (mid) {
      final index = _upList.indexWhere((e) => e.mid == mid);
      final pageController = _pageController;
      if (index < 0 || pageController == null || !pageController.hasClients) {
        return;
      }
      if (pageController.page?.round() != index) {
        pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _midWorker?.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  List<UpItem> _resolveUpList(LoadingState<FollowUpModel> state) {
    // 「全部动态」不是真实 UP，不参与分页
    if (state case Success(:final response)) {
      return response.upList?.where((e) => e.mid != -1).toList() ??
          const <UpItem>[];
    }
    return const <UpItem>[];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Obx(() {
      final upList = _resolveUpList(_controller.loadingState.value);
      if (upList.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      _upList = upList;

      var index = upList.indexWhere((e) => e.mid == _controller.currentMid);
      if (index < 0) index = 0;
      _pageController ??= PageController(initialPage: index);

      final currentUp = upList[index];
      return Column(
        children: [
          _header(context, colorScheme, currentUp),
          Expanded(
            // 竖向滚动优先 + 水平阈值 30px，避免上下刷动态时误触翻页
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: <Type, GestureRecognizerFactory>{
                  _LowSensitivityHorizontalDragRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        _LowSensitivityHorizontalDragRecognizer
                      >(
                        () => _LowSensitivityHorizontalDragRecognizer(
                          debugOwner: this,
                        ),
                        (instance) {
                          instance
                            ..onStart = _onDragStart
                            ..onUpdate = _onDragUpdate
                            ..onEnd = _onDragEnd
                            ..onCancel = _onDragCancel;
                        },
                      ),
                },
                child: PageView.builder(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              itemCount: upList.length,
              onPageChanged: (page) {
                _controller.onSwipeUp(upList[page].mid);
              },
              itemBuilder: (context, page) {
                final up = upList[page];
                return _UpDynamicsFeed(
                  key: ValueKey(up.mid),
                  mid: up.mid,
                );
              },
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  /// 竖向滚动时间戳：300ms 内忽略横向手势
  int? _verticalScrollTs;
  double? _dragStartPixels;
  double _dragDx = 0;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null &&
        notification.metrics.axis == Axis.vertical) {
      _verticalScrollTs = DateTime.now().millisecondsSinceEpoch;
    }
    return false;
  }

  ScrollPosition? get _pagePosition =>
      _pageController?.hasClients == true ? _pageController!.position : null;

  bool get _verticalActive {
    final ts = _verticalScrollTs;
    return ts != null && DateTime.now().millisecondsSinceEpoch - ts < 300;
  }

  void _onDragStart(DragStartDetails details) {
    _dragDx = 0;
    // 刚发生过竖向滚动，直接忽略这次横滑
    _dragStartPixels = _verticalActive ? null : _pagePosition?.pixels;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragDx += details.delta.dx;
    final start = _dragStartPixels;
    final position = _pagePosition;
    if (start == null || position == null) return;
    position.jumpTo(
      (start - _dragDx).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  void _onDragEnd(DragEndDetails details) {
    final start = _dragStartPixels;
    _dragStartPixels = null;
    if (start == null) return;
    final pageController = _pageController;
    if (pageController == null || !pageController.hasClients) return;
    final page = pageController.page ?? start;
    var target = page.round();
    if (_dragDx < -30) {
      target = page.floor() + 1;
    } else if (_dragDx > 30) {
      target = page.ceil() - 1;
    }
    _dragDx = 0;
    final maxPage = _upList.isEmpty ? 0 : _upList.length - 1;
    pageController.animateToPage(
      target.clamp(0, maxPage),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _onDragCancel() {
    final start = _dragStartPixels;
    _dragStartPixels = null;
    _dragDx = 0;
    if (start == null) return;
    final pageController = _pageController;
    if (pageController != null && pageController.hasClients) {
      pageController.animateToPage(
        (pageController.page ?? 0).round(),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _header(BuildContext context, ColorScheme colorScheme, UpItem up) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${up.uname ?? ''} 的动态',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            tooltip: '退出 UP 动态',
            onPressed: widget.onClose ?? _controller.exitUpMode,
            icon: const Icon(Icons.close, size: 20),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// 单个 UP 的动态流（独立分页，互不干扰）
class _UpDynamicsFeed extends StatefulWidget {
  const _UpDynamicsFeed({super.key, required this.mid});

  final int mid;

  @override
  State<_UpDynamicsFeed> createState() => _UpDynamicsFeedState();
}

class _UpDynamicsFeedState extends State<_UpDynamicsFeed>
    with AutomaticKeepAliveClientMixin {
  final List<DynamicItemModel> _list = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  String? _offset;
  bool _loading = false;
  bool _isEnd = false;
  String? _errMsg;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading) return;
    if (!refresh && _isEnd) return;
    _loading = true;
    if (refresh) {
      _offset = null;
      _isEnd = false;
      _errMsg = null;
    }
    final res = await DynamicsHttp.followDynamic(
      type: DynamicsTabType.up,
      hostMid: widget.mid,
      offset: _offset,
    );
    if (!mounted) {
      _loading = false;
      return;
    }
    setState(() {
      _loading = false;
      switch (res) {
        case Success(:final response):
          final items = response.items ?? const <DynamicItemModel>[];
          if (refresh) _list.clear();
          _list.addAll(items);
          _offset = response.offset;
          _isEnd = response.hasMore != true;
          _errMsg = null;
        case Error(:final errMsg):
          _errMsg = errMsg;
          _isEnd = true;
        case Loading():
          break;
      }
    });
  }

  /// 展开折叠的动态（与 tab 页 onUnfold 语义一致：让后续条目可见）
  void _unfoldAt(int index) {
    final ids = _list[index].modules.moduleFold?.ids;
    if (ids == null || ids.isEmpty) return;
    final end = index + ids.length + 1;
    for (var i = index + 1; i < end && i < _list.length; i++) {
      _list[i].visible = true;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_list.isEmpty) {
      if (_loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_errMsg != null) {
        return HttpError(errMsg: _errMsg, onReload: () => _load(refresh: true));
      }
    }
    return refreshIndicator(
      key: _refreshKey,
      onRefresh: () => _load(refresh: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100),
            sliver: SliverList.builder(
              itemCount: _list.length,
              itemBuilder: (context, index) {
                if (index == _list.length - 1) {
                  _load();
                }
                final item = _list[index];
                return DynamicPanel(
                  item: item,
                  onUnfold: () => _unfoldAt(index),
                  onRemove: (_) => setState(() => _list.removeAt(index)),
                  onBlock: () => setState(() => _list.removeAt(index)),
                  onUpdate: (newItem) {
                    setState(() => _list[index] = newItem);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 水平拖拽识别器：触发阈值由默认约 18px 提高到 30px，
/// 减少上下滑动时被误判为横向翻页
class _LowSensitivityHorizontalDragRecognizer
    extends HorizontalDragGestureRecognizer {
  _LowSensitivityHorizontalDragRecognizer({super.debugOwner});

  static const double _threshold = 30;

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) => globalDistanceMoved.abs() > _threshold;
}
