#!/bin/bash
set -euo pipefail

# 为每个 fpk 构建生成唯一的安装向导（含预生成密钥，安装前展示）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_FILE="${SCRIPT_DIR}/../fnos/wizard/install"

gen_secret() {
    local len="${1:-16}"
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -hex "$len"
    else
        head -c "$((len * 2))" /dev/urandom | tr -dc 'a-f0-9' | head -c "$((len * 2))"
    fi
}

MGMT_SECRET="$(gen_secret 16)"
API_KEY="$(gen_secret 16)"
PANEL_ADMIN_KEY="$(gen_secret 16)"

cat > "${OUT_FILE}" <<EOF
[
    {
        "stepTitle": "安装说明",
        "items": [
            {
                "type": "tips",
                "helpText": "<b>CLIProxyAPI Plus + CPA-Manager-Plus</b> 将 Gemini CLI、Codex、Claude Code、Grok 等 CLI 订阅封装为 OpenAI/Gemini/Claude 兼容 API，并内置增强管理面板（缓存命中、费用估算、请求监控、SQLite 持久化统计）。<br>本包为原生二进制版本，无需 Docker。<br><br>下一步将显示为本机生成的密钥，<b>请在确认安装前妥善保存</b>；安装后配置文件位于「文件管理 → 应用文件 → CLIProxyAPI」（<code>/vol1/@appshare/CLIProxyAPI</code>）。<br><br>项目：<a href=\"https://github.com/kaitranntt/CLIProxyAPIPlus\" target=\"_blank\">CLIProxyAPI Plus</a> · 面板：<a href=\"https://github.com/seakee/CPA-Manager-Plus\" target=\"_blank\">CPA-Manager-Plus</a>"
            }
        ]
    },
    {
        "stepTitle": "安装配置",
        "items": [
            {
                "type": "text",
                "field": "wizard_port",
                "label": "API 端口",
                "initValue": "8317",
                "rules": [
                    { "required": true, "message": "请输入端口号" },
                    { "pattern": "^[0-9]+$", "message": "端口必须为数字" }
                ]
            },
            {
                "type": "text",
                "field": "wizard_panel_port",
                "label": "管理面板端口",
                "initValue": "18317",
                "rules": [
                    { "required": true, "message": "请输入端口号" },
                    { "pattern": "^[0-9]+$", "message": "端口必须为数字" }
                ]
            }
        ]
    },
    {
        "stepTitle": "安装密钥（请保存）",
        "items": [
            {
                "type": "tips",
                "helpText": "<b>请立即复制并保存以下密钥</b>。管理面板地址：<code>http://&lt;本机IP&gt;:&lt;面板端口&gt;/management.html</code>（默认面板端口 18317）。登录面板请使用「面板登录密钥」。"
            },
            {
                "type": "text",
                "field": "wizard_mgmt_secret",
                "label": "CPA 管理密钥",
                "initValue": "${MGMT_SECRET}",
                "rules": [
                    { "required": true, "message": "管理密钥不能为空" },
                    { "min": 16, "message": "管理密钥长度不足" }
                ]
            },
            {
                "type": "text",
                "field": "wizard_panel_admin_key",
                "label": "面板登录密钥",
                "initValue": "${PANEL_ADMIN_KEY}",
                "rules": [
                    { "required": true, "message": "面板登录密钥不能为空" },
                    { "min": 16, "message": "面板登录密钥长度不足" }
                ]
            },
            {
                "type": "text",
                "field": "wizard_api_key",
                "label": "API Key",
                "initValue": "${API_KEY}",
                "rules": [
                    { "required": true, "message": "API Key 不能为空" },
                    { "min": 16, "message": "API Key 长度不足" }
                ]
            }
        ]
    }
]
EOF

echo "Generated install wizard with pre-install credentials → ${OUT_FILE}"
