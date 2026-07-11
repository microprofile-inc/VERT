#!/usr/bin/env bash
set -euo pipefail

# ============================================
# FormatCube Let's Encrypt 证书签发 + OSS 上传
# 域名: formatcube.com
# ============================================

DOMAIN="formatcube.com"
BUCKET="format-cube"
REGION="oss-cn-hongkong"
ENDPOINT="$REGION.aliyuncs.com"
CERT_DIR="$HOME/.acme.sh/$DOMAIN"
CERT_BACKUP_DIR="/tmp/formatcube-cert"

echo "=========================================="
echo "  Let's Encrypt 证书签发"
echo "  域名: ${DOMAIN} *.${DOMAIN}"
echo "  DNS: 阿里云 DNS-01 验证"
echo "=========================================="

# 1. 读取阿里云凭证（从 ossutilconfig）
echo ""
echo "[1/6] 读取阿里云凭证..."
ACCESS_KEY_ID=$(grep accessKeyID ~/.ossutilconfig | cut -d= -f2)
ACCESS_KEY_SECRET=$(grep accessKeySecret ~/.ossutilconfig | cut -d= -f2)

if [ -z "$ACCESS_KEY_ID" ] || [ -z "$ACCESS_KEY_SECRET" ]; then
	echo "❌ 无法从 ~/.ossutilconfig 读取凭证"
	exit 1
fi
echo "  ✓ AccessKey: ${ACCESS_KEY_ID:0:8}****"

export Ali_Key="$ACCESS_KEY_ID"
export Ali_Secret="$ACCESS_KEY_SECRET"

# 2. 检测/安装 acme.sh
echo ""
echo "[2/6] 检测 acme.sh..."
ACME_SH="$HOME/.acme.sh/acme.sh"
if [ ! -f "$ACME_SH" ]; then
	echo "  → 安装 acme.sh..."
	curl https://get.acme.sh | sh -s email=admin@${DOMAIN}
	echo "  ✓ acme.sh 已安装"
else
	echo "  ✓ acme.sh 已存在"
	$ACME_SH --upgrade --auto-upgrade 2>/dev/null || true
fi

# 设置默认 CA 为 Let's Encrypt
$ACME_SH --set-default-ca --server letsencrypt 2>/dev/null || true

# 3. 签发证书（DNS-01 验证）— 自动检测到期时间
echo ""
echo "[3/6] 检查证书状态..."

# 检查已有证书是否即将到期（30 天内）
ECC_CERT="$HOME/.acme.sh/${DOMAIN}_ecc/fullchain.cer"
NEED_ISSUE=1

if [ -f "$ECC_CERT" ]; then
	if command -v openssl &>/dev/null; then
		EXPIRY_EPOCH=$(openssl x509 -in "$ECC_CERT" -noout -enddate 2>/dev/null | cut -d= -f2)
		if [ -n "$EXPIRY_EPOCH" ]; then
			EXPIRY_TS=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$EXPIRY_EPOCH" +%s 2>/dev/null || date -d "$EXPIRY_EPOCH" +%s 2>/dev/null || echo 0)
			NOW_TS=$(date +%s)
			DAYS_LEFT=$(( (EXPIRY_TS - NOW_TS) / 86400 ))
			echo "  → 已有证书，到期时间: $EXPIRY_EPOCH"
			echo "  → 剩余有效期: ${DAYS_LEFT} 天"
			if [ $DAYS_LEFT -gt 30 ]; then
				echo "  ✓ 证书仍有效（>30天），跳过续签"
				NEED_ISSUE=0
			else
				echo "  ⚠️  即将到期（≤30天），执行续签..."
				NEED_ISSUE=2
			fi
		fi
	else
		echo "  ⚠️  openssl 不可用，无法检查到期时间，尝试续签"
		NEED_ISSUE=2
	fi
else
	echo "  → 未找到已有证书，首次签发"
fi

if [ $NEED_ISSUE -eq 1 ]; then
	echo "  → 首次签发 ${DOMAIN} + *.${DOMAIN}..."
	$ACME_SH --issue -d "$DOMAIN" -d "*.$DOMAIN" --dns dns_ali \
		--keylength ec-256 2>&1 || {
		echo ""
		echo "❌ 签发失败。请检查："
		echo "  - 域名 ${DOMAIN} 的 DNS 是否已指向阿里云 DNS"
		echo "  - AccessKey 是否有 AliyunDNSFullAccess 权限"
		exit 1
	}
	CERT_CHANGED=1
elif [ $NEED_ISSUE -eq 2 ]; then
	echo "  → 续签 ${DOMAIN} + *.${DOMAIN}..."
	if $ACME_SH --renew -d "$DOMAIN" -d "*.$DOMAIN" --dns dns_ali \
		--ecc --force 2>&1; then
		CERT_CHANGED=1
	else
		echo "  ⚠️  续签失败，继续使用现有证书"
		CERT_CHANGED=0
	fi
else
	CERT_CHANGED=0
fi

# 4. 导出证书到本地
echo ""
echo "[4/6] 导出证书..."
mkdir -p "$CERT_BACKUP_DIR"
$ACME_SH --install-cert -d "$DOMAIN" --ecc \
	--fullchain-file "$CERT_BACKUP_DIR/fullchain.cer" \
	--key-file       "$CERT_BACKUP_DIR/private.key" \
	--cert-file      "$CERT_BACKUP_DIR/cert.cer" 2>&1

echo "  ✓ 证书文件:"
for f in "$CERT_BACKUP_DIR"/*; do
	[ -f "$f" ] && echo "    $(basename "$f") ($(ls -lh "$f" | awk '{print $5}'))"
done

if command -v openssl &>/dev/null; then
	EXPIRY=$(openssl x509 -in "$CERT_BACKUP_DIR/cert.cer" -noout -enddate 2>/dev/null | cut -d= -f2)
	echo "  ✓ 有效期至: $EXPIRY"
fi

# 5. 上传证书到 OSS（仅证书变更时上传）
echo ""
echo "[5/6] 上传证书到 OSS..."
if [ $CERT_CHANGED -eq 0 ]; then
	echo "  ⊘ 证书未变更，跳过上传"
else

# 上传 fullchain
ossutil cp "$CERT_BACKUP_DIR/fullchain.cer" "oss://${BUCKET}/ssl/fullchain.cer" \
	--endpoint "$ENDPOINT" \
	--meta "Content-Type:application/x-pem-file;Cache-Control:no-cache" \
	--force >/dev/null 2>&1 && echo "  ✓ ssl/fullchain.cer" || echo "  ✗ fullchain 上传失败"

# 上传 private key
ossutil cp "$CERT_BACKUP_DIR/private.key" "oss://${BUCKET}/ssl/private.key" \
	--endpoint "$ENDPOINT" \
	--meta "Content-Type:application/x-pem-file;Cache-Control:no-cache" \
	--force >/dev/null 2>&1 && echo "  ✓ ssl/private.key" || echo "  ✗ private.key 上传失败"

# 上传 cert
ossutil cp "$CERT_BACKUP_DIR/cert.cer" "oss://${BUCKET}/ssl/cert.cer" \
	--endpoint "$ENDPOINT" \
	--meta "Content-Type:application/x-pem-file;Cache-Control:no-cache" \
	--force >/dev/null 2>&1 && echo "  ✓ ssl/cert.cer" || echo "  ✗ cert 上传失败"

fi

# 5b. 上传证书到阿里云 SSL 证书管理服务
echo ""
echo "[5b/6] 上传证书到阿里云 SSL 证书管理服务..."
if [ $CERT_CHANGED -eq 0 ]; then
	echo "  ⊘ 证书未变更，跳过"
else
	# 5b. 上传到阿里云 SSL 证书服务
	echo ""
	echo "[5b/6] 上传证书到阿里云 SSL 证书服务..."
	CERT_CONTENT=$(cat "$CERT_BACKUP_DIR/fullchain.cer")
	KEY_CONTENT=$(cat "$CERT_BACKUP_DIR/private.key")
	UPLOAD_RESULT=$(aliyun --region cn-hongzhou --endpoint cas.aliyuncs.com \
		cas UploadUserCertificate \
		--Name "${DOMAIN}-letsencrypt" \
		--Cert "$CERT_CONTENT" \
		--Key "$KEY_CONTENT" 2>&1)
	CERT_ID=$(echo "$UPLOAD_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('CertId',''))" 2>/dev/null || echo "")
	if [ -n "$CERT_ID" ]; then
		echo "  ✓ 证书已上传 (ID: $CERT_ID)"
	else
		echo "  ⚠️ 上传结果: $UPLOAD_RESULT"
		# 尝试从已有证书列表查找
		CERT_ID=$(aliyun --region cn-hongzhou --endpoint cas.aliyuncs.com \
			cas ListUserCertificateOrder --ShowSize 50 2>&1 | \
			python3 -c "import sys,json; certs=json.load(sys.stdin).get('CertificateOrderList',[]); print(next((c.get('InstanceId','') for c in certs if '$DOMAIN' in c.get('Domain','')), ''))" 2>/dev/null || echo "")
	fi

	# 5c. 绑定证书到 OSS 自定义域名
	if [ -n "$CERT_ID" ]; then
		echo ""
		echo "[5c/6] 绑定证书到 OSS 自定义域名..."
		CERT_XML="/tmp/cname-cert.xml"
		cat > "$CERT_XML" << XMLEOF
<?xml version="1.0" encoding="utf-8"?>
<BucketCnameConfiguration>
  <Cname>
    <Domain>${DOMAIN}</Domain>
    <CertificateConfiguration>
      <CertId>${CERT_ID}</CertId>
    </CertificateConfiguration>
  </Cname>
</BucketCnameConfiguration>
XMLEOF
		ossutil bucket-cname --method put --item certificate \
			"oss://${BUCKET}" "$CERT_XML" \
			--endpoint "$ENDPOINT" 2>&1 && echo "  ✓ 证书已绑定到 ${DOMAIN}" || echo "  ✗ 绑定失败"
	fi
fi

# 6. 完成提示
echo ""
echo "[6/6] 完成!"
echo "=========================================="
echo "  证书文件: $CERT_BACKUP_DIR/"
echo "  OSS 备份: oss://${BUCKET}/ssl/"
echo "  SSL 证书服务: ${DOMAIN}-letsencrypt"
echo "=========================================="
echo ""
echo "📋 绑定到阿里云 CDN / 自定义域名:"
echo "  1. 登录阿里云控制台 → CDN → 域名管理"
echo "  2. 选择 formatcube.com → HTTPS 配置 → 选择证书"
echo "  3. 在下拉列表中选择「formatcube.com-letsencrypt」"
echo "  （证书已自动上传到阿里云 SSL 证书管理服务）"
echo ""
echo "🔄 自动续签 (crontab):"
echo "  $ACME_SH --renew -d $DOMAIN --ecc --dns dns_ali --force"
echo "  续签后重新上传证书到 CDN/OSS"
echo ""
