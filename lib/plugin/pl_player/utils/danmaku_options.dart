import 'package:PiliPlus/utils/extension/box_ext.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/models/common/danmaku/danmaku_font_sync_mode.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';

abstract final class DanmakuOptions {
  static final Set<int> blockTypes = Pref.danmakuBlockType;
  static bool blockColorful = blockTypes.contains(6);

  static int danmakuWeight = Pref.danmakuWeight;
  static double danmakuFontScaleFS = Pref.danmakuFontScaleFS;
  static double danmakuFontScale = Pref.danmakuFontScale;
  static int danmakuFontWeight = Pref.danmakuFontWeight;
  static double danmakuShowArea = Pref.danmakuShowArea;

  /// 弹幕显示行数；>0 时按行数换算显示区域，0 表示沿用 [danmakuShowArea]
  static int danmakuRows = Pref.danmakuRows;

  /// 弹幕画布高度（px），由 danmaku 视图在构建时回填，用于行数→区域换算
  static double canvasHeight = 0;

  /// 行数换算为面积比例：一行高 = 字号 × 行高倍数
  ///
  /// [height] 为当前画布高度（px）；传了就用它，避免依赖可变静态值导致行数串档。
  static double areaFromRows(double fontSize, [double? height]) {
    final canvas = (height != null && height > 0) ? height : canvasHeight;
    if (danmakuRows <= 0 || canvas <= 0) return danmakuShowArea;
    return (danmakuRows * fontSize * danmakuLineHeight / canvas).clamp(
      0.05,
      1.0,
    );
  }
  static double danmakuDuration = Pref.danmakuDuration;
  static double danmakuStaticDuration = Pref.danmakuStaticDuration;
  static double danmakuStrokeWidth = Pref.danmakuStrokeWidth;
  static bool danmakuFixedV = Pref.danmakuFixedV;
  static bool danmakuStatic2Scroll = Pref.danmakuStatic2Scroll;
  static bool danmakuMassiveMode = Pref.danmakuMassiveMode;
  static double danmakuLineHeight = Pref.danmakuLineHeight;

  static bool get sameFontScale => danmakuFontScale == danmakuFontScaleFS;

  static DanmakuOption get({
    required bool notFullscreen,
    double speed = 1.0,
    double? canvasHeight,
  }) {
    String? fontFamily;
    if (!Pref.enableCustomDanmakuFont || Pref.danmakuFontSyncMode == DanmakuFontSyncMode.system) {
      fontFamily = null;
    } else if (Pref.danmakuFontSyncMode == DanmakuFontSyncMode.global) {
      fontFamily = Pref.appFont;
    } else {
      fontFamily = Pref.customDanmakuFontFamily;
    }

    final fontSize = 15 * (notFullscreen ? danmakuFontScale : danmakuFontScaleFS);
    return DanmakuOption(
      fontSize: fontSize,
      fontWeight: danmakuFontWeight,
      area: areaFromRows(fontSize, canvasHeight),
      duration: danmakuDuration / speed,
      staticDuration: danmakuStaticDuration / speed,
      hideBottom: blockTypes.contains(4),
      hideScroll: blockTypes.contains(2),
      hideTop: blockTypes.contains(5),
      hideSpecial: blockTypes.contains(7),
      strokeWidth: danmakuStrokeWidth,
      fontFamily: fontFamily,
      scrollFixedVelocity: danmakuFixedV,
      massiveMode: danmakuMassiveMode,
      static2Scroll: danmakuStatic2Scroll,
      safeArea: true,
      lineHeight: danmakuLineHeight,
    );
  }

  static Future<void>? save(double danmakuOpacity) {
    return GStorage.setting.putAllNE({
      SettingBoxKey.danmakuBlockType: blockTypes.toList(),
      SettingBoxKey.danmakuShowArea: danmakuShowArea,
      SettingBoxKey.danmakuRows: danmakuRows,
      SettingBoxKey.danmakuFontScale: danmakuFontScale,
      SettingBoxKey.danmakuFontScaleFS: danmakuFontScaleFS,
      SettingBoxKey.danmakuDuration: danmakuDuration,
      SettingBoxKey.danmakuStaticDuration: danmakuStaticDuration,
      SettingBoxKey.danmakuStrokeWidth: danmakuStrokeWidth,
      SettingBoxKey.danmakuFontWeight: danmakuFontWeight,
      SettingBoxKey.danmakuLineHeight: danmakuLineHeight,
      SettingBoxKey.danmakuMassiveMode: danmakuMassiveMode,
      SettingBoxKey.danmakuStatic2Scroll: danmakuStatic2Scroll,
      SettingBoxKey.danmakuFixedV: danmakuFixedV,
      SettingBoxKey.danmakuWeight: danmakuWeight,
      SettingBoxKey.danmakuOpacity: danmakuOpacity,
    });
  }
}
