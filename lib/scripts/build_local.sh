#!/usr/bin/env bash
# 本地一键构建：版本号 = 构建日期
#   versionName = yyyyMMddHHmm（如 202610301316）
#   versionCode = yyyyMMdd（Android versionCode 是 int32，12 位日期会溢出，故用 8 位）
# 用法：bash lib/scripts/build_local.sh [arm64|universal]
set -e
# 脚本位于 lib/scripts/，项目根是其上上级
cd "$(dirname "$0")/../.."

ABI="${1:-arm64}"
STAMP=$(date +%Y%m%d%H%M)
DAY=$(date +%Y%m%d)

# commit hash：优先本目录 git，其次 pilione-repo（实际版本管理仓库）
HASH=$(git rev-parse --short=9 HEAD 2>/dev/null || git -C ../pilione-repo rev-parse --short=9 HEAD 2>/dev/null || echo 'N/A')

cat > pili_release.json <<EOF
{"pili.name":"$STAMP","pili.code":$STAMP,"pili.hash":"$HASH","pili.time":$(date +%s)}
EOF
echo ">> pili_release.json: name=$STAMP code=$STAMP hash=$HASH"

if [ "$ABI" = "universal" ]; then
  flutter build apk --release --build-number="$DAY" --build-name="$STAMP" \
    --dart-define-from-file=pili_release.json --pub
  OUT=build/app/outputs/flutter-apk/app-release.apk
else
  flutter build apk --release --target-platform "android-$ABI" \
    --build-number="$DAY" --build-name="$STAMP" \
    --dart-define-from-file=pili_release.json --pub
  OUT=build/app/outputs/flutter-apk/app-release.apk
fi

DEST="../Pilione-$STAMP-$ABI.apk"
cp "$OUT" "$DEST"
echo ">> APK: $DEST (versionName=$STAMP versionCode=$DAY)"
