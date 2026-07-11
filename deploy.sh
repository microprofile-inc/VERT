#!/usr/bin/env bash
set -euo pipefail

# ============================================
# FormatCube 部署脚本 → 阿里云 OSS
# ============================================

BUCKET="format-cube"
OSS_PATH="oss://$BUCKET"
REGION="oss-cn-hongkong"
ENDPOINT="$REGION.aliyuncs.com"

echo "=========================================="
echo "  FormatCube → 阿里云 OSS 部署"
echo "  Bucket: $BUCKET"
echo "  Region: $REGION"
echo "=========================================="

# 1. 设置生产环境变量
export PUB_ENV=production
export PUB_HOSTNAME=formatcube.com
export PUB_DISABLE_ALL_EXTERNAL_REQUESTS=true

echo ""
echo "[1/4] 构建项目..."
bun run build

echo ""
echo "[2/4] 检查构建产物..."
if [ ! -d "build" ]; then
	echo "❌ build/ 目录不存在，构建失败"
	exit 1
fi
BUILD_SIZE=$(du -sh build/ | cut -f1)
WASM_COUNT=$(find build/ -name "*.wasm" | wc -l | tr -d ' ')
HTML_COUNT=$(find build/ -name "*.html" | wc -l | tr -d ' ')
echo "  产物大小: $BUILD_SIZE"
echo "  WASM 文件: $WASM_COUNT"
echo "  HTML 页面: $HTML_COUNT"

echo ""
echo "[3/4] 上传到 OSS..."

# 上传 HTML 文件 — 不缓存（每次更新都拉最新）
echo "  → 上传 HTML 文件 (no-cache)..."
find build/ -name "*.html" | while read -r f; do
	REMOTE="${f#build/}"
	ossutil cp "$f" "$OSS_PATH/$REMOTE" \
		--endpoint "$ENDPOINT" \
		--meta "Content-Type:text/html;Cache-Control:no-cache" \
		--force >/dev/null 2>&1 && echo "    ✓ $REMOTE" || echo "    ✗ $REMOTE"
done

# 上传 WASM 文件 — 正确的 MIME 类型
echo "  → 上传 WASM 文件 (application/wasm)..."
find build/ -name "*.wasm" | while read -r f; do
	REMOTE="${f#build/}"
	ossutil cp "$f" "$OSS_PATH/$REMOTE" \
		--endpoint "$ENDPOINT" \
		--meta "Content-Type:application/wasm" \
		--force >/dev/null 2>&1 && echo "    ✓ $REMOTE" || echo "    ✗ $REMOTE"
done

# 上传 JS/CSS/字体/图片等静态资源（带 hash，可长期缓存）
echo "  → 上传 _app/ 静态资源 (long cache)..."
ossutil cp -r "build/_app/" "$OSS_PATH/_app/" \
	--endpoint "$ENDPOINT" \
	--update \
	--meta "Cache-Control:public, max-age=31536000, immutable" >/dev/null 2>&1 \
	&& echo "    ✓ _app/ (已更新)" || echo "    ✗ _app/"

# 上传其他根目录文件（favicon, manifest, robots, sitemap, sw.js 等）
echo "  → 上传根目录文件..."
for f in build/favicon.png build/manifest.json build/robots.txt build/sitemap.xml build/sw.js build/banner.png build/lettermark.jpg build/lettermark_maskable.png; do
	if [ -f "$f" ]; then
		REMOTE="${f#build/}"
		ossutil cp "$f" "$OSS_PATH/$REMOTE" \
			--endpoint "$ENDPOINT" \
			--meta "Cache-Control:no-cache" \
			--force >/dev/null 2>&1 && echo "    ✓ $REMOTE" || echo "    ✗ $REMOTE"
	fi
done

# 单独上传 pandoc.wasm（在根目录，50MB）
if [ -f "build/pandoc.wasm" ]; then
	echo "  → 上传 pandoc.wasm (50MB)..."
	ossutil cp "build/pandoc.wasm" "$OSS_PATH/pandoc.wasm" \
		--endpoint "$ENDPOINT" \
		--meta "Content-Type:application/wasm" \
		--force >/dev/null 2>&1 \
		&& echo "    ✓ pandoc.wasm" || echo "    ✗ pandoc.wasm"
fi

echo ""
echo "[4/4] 部署完成!"
echo "=========================================="
echo "  访问地址: https://$BUCKET.$ENDPOINT"
echo "  自定义域名: https://formatcube.com"
echo "=========================================="
echo ""
echo "⚠️  注意事项:"
echo "  - 确保已在 OSS 控制台开启静态网站托管"
echo "  - 默认首页设为 index.html，默认 404 页设为 index.html"
echo "  - 如需 HTTPS / 自定义域名，请配置阿里云 CDN"
echo "  - WASM 需要 COOP/COEP 头（通过 CDN 配置）"
echo ""
