import 'package:PiliPlus/common/widgets/appbar/appbar.dart';
import 'package:PiliPlus/common/widgets/flutter/popup_menu.dart';
import 'package:PiliPlus/common/widgets/flutter/pop_scope.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/gesture/horizontal_drag_gesture_recognizer.dart';
import 'package:PiliPlus/common/widgets/keep_alive_wrapper.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart'
    show tabBarScrollPhysics;
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/history/list.dart';
import 'package:PiliPlus/pages/history/base_controller.dart';
import 'package:PiliPlus/pages/history/controller.dart';
import 'package:PiliPlus/pages/history/widgets/item.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.type, this.embedded = false});

  final String? type;

  /// 作为底栏标签页嵌入主界面时为 true：
  /// 1. 背景透明，透出主界面的统一渐变；
  /// 2. AppBar 不再自行让出状态栏高度（主界面已让出，否则顶部会多出一大块空白）。
  /// 通过 /history 路由打开时保持 false，维持原有不透明背景与状态栏留白。
  final bool embedded;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  late final HistoryController _historyController;
  late final String _controllerTag = widget.type ?? 'all';

  /// 控制器是否由本页面创建。
  /// 底栏「历史」与「我的 → 观看记录」会共用同一个 tag，若都用 Get.put，
  /// 后进者会顶替前者且不触发 onClose（TabController 泄漏），
  /// 并让「再点一次刷新」刷到已关闭页面的实例。
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = !Get.isRegistered<HistoryController>(tag: _controllerTag);
    _historyController = _ownsController
        ? Get.put(HistoryController(widget.type), tag: _controllerTag)
        : Get.find<HistoryController>(tag: _controllerTag);
  }

  HistoryController currCtr([int? index]) {
    try {
      index ??= _historyController.tabController!.index;
      if (index != 0) {
        return Get.find<HistoryController>(
          tag: _historyController.tabs[index - 1].type,
        );
      }
    } catch (_) {}
    return _historyController;
  }

  @override
  void dispose() {
    // 只有创建者负责回收；共用实例时由另一处页面回收，
    // 否则会把仍在使用的控制器删掉（历史上这里还误删了共享的 HistoryBaseController）
    if (_ownsController) {
      Get.delete<HistoryController>(tag: _controllerTag);
      Get.delete<HistoryBaseController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final padding = MediaQuery.viewPaddingOf(context);
    Widget child = refreshIndicator(
      onRefresh: _historyController.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _historyController.scrollController,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: 7,
              bottom: padding.bottom + 100,
            ),
            sliver: Obx(
              () => _buildBody(_historyController.loadingState.value),
            ),
          ),
        ],
      ),
    );
    if (widget.type != null) {
      return child;
    }
    return Obx(
      () {
        final enableMultiSelect =
            _historyController.baseCtr.enableMultiSelect.value;
        return popScope(
          canPop: !enableMultiSelect,
          onPopInvokedWithResult: (didPop, result) {
            if (enableMultiSelect) {
              currCtr().handleSelect();
            }
          },
          child: SimpleScaffold(
            // 嵌入底栏时透明，让主界面的渐变背景透上来，与首页/动态保持一致
            backgroundColor: widget.embedded ? Colors.transparent : null,
            appBar: MultiSelectAppBarWidget(
              visible: enableMultiSelect,
              ctr: currCtr(),
              // 嵌入底栏时与普通 AppBar 一致透明化，避免进入多选时背景断层
              backgroundColor: widget.embedded ? Colors.transparent : null,
              child: _buildAppBar,
            ),
            body: Padding(
              padding: .only(left: padding.left, right: padding.right),
              child: Obx(() {
                final tabs = _historyController.tabs;
                if (tabs.isEmpty) {
                  return child;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ?_buildPauseTip,
                    TabBar(
                      controller: _historyController.tabController,
                      onTap: (index) {
                        if (!_historyController
                            .tabController!
                            .indexIsChanging) {
                          currCtr().scrollController.animToTop();
                        } else {
                          if (enableMultiSelect) {
                            currCtr(
                              _historyController.tabController!.previousIndex,
                            ).handleSelect();
                          }
                        }
                      },
                      tabs: [
                        const Tab(text: '全部'),
                        ...tabs.map((item) => Tab(text: item.name)),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        physics: enableMultiSelect
                            ? const NeverScrollableScrollPhysics()
                            : tabBarScrollPhysics,
                        controller: _historyController.tabController,
                        horizontalDragGestureRecognizer:
                            CustomHorizontalDragGestureRecognizer.new,
                        children: [
                          KeepAliveWrapper(child: child),
                          ...tabs.map(
                            (item) => HistoryPage(type: item.type),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  AppBar get _buildAppBar => AppBar(
    // 嵌入底栏时主界面已让出状态栏高度，AppBar 不再重复让出，否则顶部会空一大块
    primary: !widget.embedded,
    centerTitle: false,
    titleSpacing: 16,
    // AppBar 默认绘制 surface 底色与 surfaceTint 阴影，会盖住主界面的渐变，
    // 嵌入底栏时全部透明化，让标题行与下方列表处于同一渐变背景上
    backgroundColor: widget.embedded ? Colors.transparent : null,
    surfaceTintColor: widget.embedded ? Colors.transparent : null,
    elevation: widget.embedded ? 0 : null,
    scrolledUnderElevation: widget.embedded ? 0 : null,
    title: const Text(
      '观看记录',
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    ),
    actions: [
      IconButton(
        tooltip: '搜索',
        onPressed: () => Get.toNamed('/historySearch'),
        icon: const Icon(Icons.search_outlined),
      ),
      StaticPopupMenuButton(
        itemBuilder: (_) => [
          PopupMenuItem(
            onTap: () => _historyController.baseCtr.onPauseHistory(context),
            child: Text(
              !_historyController.baseCtr.pauseStatus.value
                  ? '暂停观看记录'
                  : '恢复观看记录',
            ),
          ),
          PopupMenuItem(
            onTap: () => _historyController.baseCtr.onClearHistory(
              context,
              () {
                _historyController.loadingState.value = const Success(null);
                if (_historyController.tabController != null) {
                  for (final item in _historyController.tabs) {
                    try {
                      Get.find<HistoryController>(
                        tag: item.type,
                      ).loadingState.value = const Success(
                        null,
                      );
                    } catch (_) {}
                  }
                }
              },
            ),
            child: const Text('清空观看记录'),
          ),
          PopupMenuItem(
            onTap: currCtr().onDelViewedHistory,
            child: const Text('删除已看记录'),
          ),
        ],
      ),
      const SizedBox(width: 6),
    ],
  );

  Widget _buildBody(LoadingState<List<HistoryItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _historyController.onLoadMore();
                  }
                  final item = response[index];
                  return HistoryItem(
                    item: item,
                    ctr: _historyController,
                    onDelete: (kid, business) =>
                        _historyController.delHistory(item),
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _historyController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _historyController.onReload,
      ),
    };
  }

  PreferredSizeWidget? get _buildPauseTip {
    if (_historyController.baseCtr.pauseStatus.value) {
      final theme = Theme.of(context).colorScheme;
      return PreferredSize(
        preferredSize: const Size.fromHeight(38),
        child: Container(
          height: 38,
          color: theme.secondaryContainer.withValues(alpha: 0.8),
          padding: const EdgeInsets.only(left: 16, right: 6),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  strutStyle: const StrutStyle(height: 1, leading: 0),
                  style: TextStyle(
                    height: 1,
                    color: theme.onSecondaryContainer,
                  ),
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: theme.onSecondaryContainer,
                        ),
                      ),
                      const TextSpan(text: ' 历史记录功能已关闭'),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _historyController.baseCtr.onPauseHistory(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 10,
                  ),
                  child: Text(
                    '点击开启',
                    strutStyle: const StrutStyle(height: 1, leading: 0),
                    style: TextStyle(height: 1, color: theme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return null;
  }

  @override
  bool get wantKeepAlive => widget.type != null;
}
