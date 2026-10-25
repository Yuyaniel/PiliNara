<div align="center">
  <img width="180" src="assets/images/logo/logo.png">
  <h1>PiliNara</h1>
  <p>第三方哔哩哔哩客户端 · 自用修改版</p>
  <p>基于 <a href="https://github.com/bggRGjQaUbCoE/PiliPlus">PiliPlus</a> / <a href="https://github.com/Starfallan/PiliNara">PiliNara</a></p>
</div>

---

## 我做了什么

本仓库在上游基础上只做了下面这些改动，上游原有功能见 [PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus)。

### 1. 高画质播放（实验性）

非大会员账号经**第三方服务**获取 1080P 以上画质，支持普通投稿视频。

**原理**：App 把网页版 `playurl` 的原始参数集（含 WBI 签名 `wts` / `w_rid`）与登录凭证打包成 JSON，`POST` 到所配置服务地址的 `/api/bzview2`；服务端用高权限账号代请求 B 站，再把标准 `playurl v2` 结果返回给 App 解析播放。App 侧不做任何解密或破解。

**设置项**（设置 → 音视频设置）：

| 设置项 | 说明 |
|---|---|
| 高画质播放（实验性） | 总开关 |
| 高画质服务地址 | 第三方服务地址，留空表示不启用 |
| 高画质目标画质 | **上限语义**：返回的流会按上限裁剪，只保留不高于该档的档位（默认 1080P 60帧） |
| 高画质请求状态 | 显示结果与失败原因，如「成功：最高 4K 超高清，共 6 档」；失败后进入冷却时会显示剩余秒数 |
| 高画质所用账号 | 确认发出去的是哪个账号（mid / 等级 / 硬币 / 大会员） |
| 查看最近一次远端请求 | 可查看并复制全文，cookie 已按 `name=***` 打码；超过 8000 字符会截断并标注原长 |
| 查看最近一次远端响应 | 同上，便于反馈问题 |
| 不忽略过短的远端流（调试） | 默认关闭。远端流比本地短 5 秒以上会判定为试看片段并丢弃 |

**兜底**：远端请求失败、返回异常、流时长异常时一律回退到原生 `playurl`，不影响正常播放。失败后 **30 秒冷却**（期间不再请求，保证起播速度），可在「高画质请求状态」看到剩余时间。

**风险提示**：该功能会把登录凭证（`SESSDATA` 等）发送到你所配置的服务地址。服务端不可信等于交出账号，请只填自己信任或自建的服务，建议用小号。

### 2. 播放进度自动点赞

设置 → 播放设置：

- `播放到指定进度自动点赞`：总开关，默认关闭
- `自动点赞进度`：滑块 10%~100%，默认 **95%**

触发规则：进度达到阈值时自动点赞；同一视频只触发一次（按 `bvid_cid` 去重，切分P 重新计算）；已点赞的视频直接跳过，不会误变成「取消赞」；未登录不触发。

### 3. 播放信息侧栏

- 位置：全屏播放器底部操作栏，**「缓存」与「分享」之间**，图标为 ⓘ
- **常驻浮层**：右侧半透明小圆角框，单行「标签: 值」排版，无标题
- 显示五项：**编码 / 分辨率 / 帧率 / 色彩矩阵 / 比特率**
  - 示例：`编码: hevc`、`分辨率: 3840x2160`、`帧率: 30.0`、`色彩矩阵: bt.709`、`比特率: 4.26 Mbps`
- **只有再次点击控件，或直接点击浮层本身才会关闭**；播放过程中常驻，不会随控制栏自动隐藏
- 比特率为实时值，每秒刷新，便于观察码率变化
- 数据来源（mpv 属性，与「更多 → 播放信息」同源）：

  | 显示项 | 来源 |
  |---|---|
  | 编码 / 帧率 | `video-track`（`codec` / `fps`） |
  | 分辨率 / 色彩矩阵 | `video-params`（`w`/`h` / `colormatrix`） |
  | 比特率 | `video-bitrate`（单位 bit/s） |

### 4. UP 动态全屏页

- **进入**：动态页点击顶部任一头像 → 打开**独立全屏页**，只显示该 UP 的动态（无 tab 栏、无底部导航）
- **标题栏**：`XX 的动态` + ✕ 关闭
- 长动态支持展开（`onUnfold`，与动态 tab 页行为一致）
- **切换**：页内左右滑动即可切换到其他 UP，标题实时更新
- **已读**：切入某个 UP 时自动清除其头像红点（本地已读），与选中态保持同步
- **返回**：✕ 或系统返回，回到动态页原状态
- 实现要点：`currentMid`（`controller.dart`）是唯一选中态；头像行用 `GlobalKey` + `ensureVisible` 自动滚动跟随并显示底部箭头指示；每个 UP 的动态流独立分页与缓存（`widgets/up_feed_pager.dart`，页面入口 `up_dynamics_page.dart`）

---

## 本地构建（Windows）

> 这个工程不是 `flutter build apk` 就能直接过的，下面几步缺一不可。

1. **Flutter 版本**：`3.47.7`（Dart 3.13.5）
2. **必须打补丁**：工程把一批 Flutter 框架私有类型改成了公开（如 `StandardBottomSheet`、`TabBarState`），需先执行：

   ```powershell
   $env:FLUTTER_ROOT="<你的 flutter 目录>"
   $env:GITHUB_WORKSPACE="<项目根目录>"
   powershell -ExecutionPolicy Bypass -File .\lib\scripts\patch.ps1 -platform android
   ```

   脚本会给 Flutter SDK 与 pub 缓存里的 `material_ui` / `cupertino_ui` 应用补丁。不打会直接报 `Type 'StandardBottomSheet' not found`。

3. **依赖镜像**（国内网络）：`android/build.gradle.kts` 与 `android/settings.gradle.kts` 已加入阿里云 + 腾讯云镜像，替代不可达的 `maven.google.com` / `jitpack.io`；`gradle-wrapper.properties` 指向腾讯云镜像。
4. **Kotlin 增量编译**：`android/gradle.properties` 中已关闭（`kotlin.incremental=false`）。工程与 `GRADLE_USER_HOME` 不在同一盘符时，增量缓存会因相对路径跨盘而报错。
5. **签名**：在 `android/` 下新建 `key.properties`，并把 `pilinara.jks` 放到 `android/app/`：

   ```properties
   storeFile=pilinara.jks
   storePassword=<你的密码>
   keyAlias=<你的别名>
   keyPassword=<你的密码>
   ```

   两个文件都已被 `.gitignore` 排除，**切勿提交**。keystore 丢失后无法再发布可覆盖安装的更新。

6. **构建并注入版本号**（不修改 `pubspec.yaml`）：

   ```powershell
   $code = [int]([DateTimeOffset]::Now.ToUnixTimeSeconds() / 60)   # 分钟时间戳，单调唯一
   $ts   = [int][DateTimeOffset]::Now.ToUnixTimeSeconds()
   $hash = (git rev-parse --short HEAD)

   flutter build apk --release --target-platform android-arm64 `
     --build-name=2.1.6 --build-number=$code `
     --dart-define=pili.code=$code --dart-define=pili.name=2.1.6 `
     --dart-define=pili.hash=$hash --dart-define=pili.time=$ts
   ```

   `--build-number` 会写进 APK 的 `versionCode`，`--dart-define` 让 App 内的「关于」页显示真实版本而不是 `SNAPSHOT+1`。

   产物：`build/app/outputs/flutter-apk/app-release.apk`

---

## 声明

- 本项目仅供个人学习和测试使用，请于下载后 24 小时内删除。
- 所用 API 均从官方渠道收集，不提供任何破解内容；高画质功能依赖第三方服务，其行为与本仓库无关，风险自负。
- 本项目基于 [PiliPala](https://github.com/guozhigq/pilipala) → [PiliPalaX](https://github.com/orz12/PiliPalaX) → [PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus) → [PiliNara](https://github.com/Starfallan/PiliNara) 一路演进而来，遵循 **GPL-3.0**，感谢原作者与上游作者的开源精神。如有侵权请联系删除。

## 致谢

- [bilibili-API-collect](https://github.com/SocialSisterYi/bilibili-API-collect)
- [media-kit](https://github.com/media-kit/media-kit)
- [dio](https://github.com/cfug/dio)
