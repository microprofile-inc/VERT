#!/usr/bin/env bash
set -euo pipefail

# ============================================
# FormatCube 部署脚本 → 阿里云 OSS
# ============================================

BUCKET="format-cube"
OSS_PATH="oss://$BUCKET"
REGION="oss-cn-hongkong"
ENDPOINT="$REGION.aliyuncs.com"

oss_upload() {
	local src="$1" remote="$2" ctype="$3" cc="$4"
	local args=("$src" "$OSS_PATH/$remote" --endpoint "$ENDPOINT" --force --meta "Content-Type:$ctype")
	[ -n "$cc" ] && args+=(--meta "Cache-Control:$cc")
	ossutil cp "${args[@]}" >/dev/null 2>&1 && echo "    ✓ $remote" || echo "    ✗ $remote"
}

echo "=========================================="
echo "  FormatCube → 阿里云 OSS 部署"
echo "  Bucket: $BUCKET"
echo "  Region: $REGION"
echo "=========================================="

# 1. 构建
export PUB_ENV=production
export PUB_HOSTNAME=formatcube.com
export PUB_DISABLE_ALL_EXTERNAL_REQUESTS=true

echo ""
echo "[1/4] 构建项目..."
bun run build

echo ""
echo "[2/4] 检查构建产物..."
if [ ! -d "build" ]; then
	echo "❌ build/ 目录不存在"
	exit 1
fi
echo "  产物大小: $(du -sh build/ | cut -f1)"
echo "  HTML: $(find build/ -name '*.html' | wc -l | tr -d ' ') 页"
echo "  WASM: $(find build/ -name '*.wasm' | wc -l | tr -d ' ') 个"

# 2. 上传
echo ""
echo "[3/4] 上传到 OSS..."

LONG_CACHE="public,max-age=31536000,immutable"
NO_CACHE="no-cache"

# HTML 文件 — no-cache
echo "  → HTML..."
find build/ -name "*.html" | while read -r f; do
	r="${f#build/}"
	oss_upload "$f" "$r" "text/html" "$NO_CACHE"
done

# JS — long cache（模块加载需要 text/javascript 或 application/javascript）
echo "  → JavaScript..."
find build/ -name "*.js" | while read -r f; do
	r="${f#build/}"
	oss_upload "$f" "$r" "application/javascript" "$LONG_CACHE"
done

# CSS — long cache
echo "  → CSS..."
find build/ -name "*.css" | while read -r f; do
	r="${f#build/}"
	oss_upload "$f" "$r" "text/css" "$LONG_CACHE"
done

# JSON — long cache
echo "  → JSON..."
find build/ -name "*.json" | while read -r f; do
	r="${f#build/}"
	oss_upload "$f" "$r" "application/json" "$LONG_CACHE"
done

# WASM
echo "  → WASM..."
find build/ -name "*.wasm" | while read -r f; do
	r="${f#build/}"
	oss_upload "$f" "$r" "application/wasm" "$LONG_CACHE"
done

# 字体 — long cache
echo "  → 字体..."
find build/ \( -name "*.woff" -o -name "*.woff2" \) | while read -r f; do
	r="${f#build/}"
	ext="${r##*.}"
	[ "$ext" = "woff2" ] && ctype="font/woff2" || ctype="font/woff"
	oss_upload "$f" "$r" "$ctype" "$LONG_CACHE"
done

# 图片 — long cache
echo "  → 图片/媒体..."
find build/ \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" -o -name "*.svg" -o -name "*.gif" -o -name "*.ico" \) | while read -r f; do
	r="${f#build/}"
	case "${r##*.}" in
		png)   ctype="image/png" ;;
		jpg|jpeg) ctype="image/jpeg" ;;
		webp)  ctype="image/webp" ;;
		svg)   ctype="image/svg+xml" ;;
		gif)   ctype="image/gif" ;;
		ico)   ctype="image/x-icon" ;;
		*)     ctype="application/octet-stream" ;;
	esac
	oss_upload "$f" "$r" "$ctype" "$LONG_CACHE"
done

# XML — no-cache
echo "  → XML..."
find build/ -name "*.xml" | while read -r f; do
	r="${f#build/}"
	oss_upload "$f" "$r" "application/xml" "$NO_CACHE"
done

# TXT — no-cache
echo "  → TXT..."
find build/ -name "*.txt" | while read -r f; do
	r="${f#build/}"
	oss_upload "$f" "$r" "text/plain" "$NO_CACHE"
done

echo ""
echo "[4/4] 部署完成!"
echo "=========================================="
echo "  访问: https://formatcube.com"
echo "  OSS:  https://$BUCKET.$ENDPOINT"
echo "=========================================="
