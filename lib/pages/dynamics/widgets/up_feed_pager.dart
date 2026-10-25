import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/dynamics.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/dynamic/dynamics_type.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/models/dynamics/up.dart';
import 'package:PiliPlus/pages/dynamics/controller.dart';
import 'package:PiliPlus/pages/dynamics/widgets/dynamic_panel.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' hide RefreshIndicatorState;

/// UP 动态分页器
///
/// 与顶部头像行共用 [DynamicsController.currentMid] 作为唯一选中态：
/// - 点头像 → [DynamicsController.onSelectUp] → currentMid 变化 → 本组件跟随翻页
/// - 左右滑动 → [DynamicsController.onSwipeUp] → currentMid 变化 → 头像行高亮跟随
class DynamicsUpPager extends StatefulWidget {
  const DynamicsUpPager({super.key, required this.dynamicsController});

  final DynamicsController dynamicsController;

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
            child: PageView.builder(
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
        ],
      );
    });
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
            onPressed: _controller.exitUpMode,
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
