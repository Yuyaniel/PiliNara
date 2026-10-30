#!/usr/bin/env bash
# 本地一键构建：版本显示 = 语义版本(构建日期)，如 2.1.6(202610301323)
#   Android versionName = 语义版本（从 pubspec 提取，如 2.1.6）
#   Android versionCode = yyyyMMdd（int32 上限 2147483647，12 位日期会溢出，故用 8 位）
#   关于页括号内        = pili.code = yyyyMMddHHmm（12 位，经 dart-define 注入）
# 用法：bash lib/scripts/build_local.sh [arm64|universal]
set -e
# 脚本位于 lib/scripts/，项目根是其上上级
cd "$(dirname "$0")/../.."

ABI="${1:-arm64}"
STAMP=$(date +%Y%m%d%H%M)
DAY=$(date +%Y%m%d)

# 语义版本从 pubspec 提取（如 2.1.6+1 → 2.1.6）
SEMVER=$(grep -E '^[[:space:]]*version:[[:space:]]*[0-9]' pubspec.yaml | head -1 | sed -E 's/^[[:space:]]*version:[[:space:]]*([0-9][0-9.]*)[[:space:]]*\+.*/\1/')
if [ -z "$SEMVER" ]; then
  echo "!! 未从 pubspec.yaml 读到语义版本" >&2
  exit 1
fi

# commit hash：优先本目录 git，其次 pilione-repo（实际版本管理仓库）
HASH=$(git rev-parse --short=9 HEAD 2>/dev/null || git -C ../pilione-repo rev-parse --short=9 HEAD 2>/dev/null || echo 'N/A')

cat > pili_release.json <<EOF
{"pili.name":"$SEMVER","pili.code":$STAMP,"pili.hash":"$HASH","pili.time":$(date +%s)}
EOF
echo ">> pili_release.json: name=$SEMVER code=$STAMP hash=$HASH"

if [ "$ABI" = "universal" ]; then
  flutter build apk --release --build-number="$DAY" --build-name="$SEMVER" \
    --dart-define-from-file=pili_release.json --pub
  OUT=build/app/outputs/flutter-apk/app-release.apk
else
  flutter build apk --release --target-platform "android-$ABI" \
    --build-number="$DAY" --build-name="$SEMVER" \
    --dart-define-from-file=pili_release.json --pub
  OUT=build/app/outputs/flutter-apk/app-release.apk
fi

DEST="../Pilione-$SEMVER($STAMP)-$ABI.apk"
cp "$OUT" "$DEST"
echo ">> APK: $DEST (versionName=$SEMVER versionCode=$DAY 显示=$SEMVER($STAMP))"
