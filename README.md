# CLIProxyAPI Plus 飞牛 OS 安装包（原生二进制）

将 [CLIProxyAPI Plus](https://github.com/kaitranntt/CLIProxyAPIPlus) 与 [CPA-Manager-Plus](https://github.com/seakee/CPA-Manager-Plus) 打包为飞牛 fnOS 可安装的 `.fpk`，**不依赖 Docker**，直接运行 Linux 二进制。

## 开源说明

本仓库仅包含 fnOS 打包脚本与配置模板，**不包含**上游二进制与任何用户密钥。

| 不提交（见 `.gitignore`） | 说明 |
|---------------------------|------|
| `dist/*.fpk` | 构建产物 |
| `fnos/wizard/install` | 构建时生成的安装向导（含预生成密钥） |
| `var/config.yaml`、`CREDENTIALS.txt` 等 | 安装后由 NAS 生成的运行时数据 |

克隆后请先构建，`build.sh` 会自动生成图标与安装向导密钥。

## 功能

| 组件 | 端口 | 说明 |
|------|------|------|
| CLIProxyAPI Plus | 8317（可改） | API 代理服务 |
| CPA-Manager-Plus | 18317（可改） | 增强管理面板：缓存命中、费用估算、请求监控、SQLite 持久化统计 |

## 安装包

构建完成后位于 `dist/`：

| 文件 | 架构 |
|------|------|
| `cliproxyapi_7.1.45-0.4_x86.fpk` | Intel/AMD (x86_64) |

## 安装步骤

1. 在飞牛 **应用中心** → **手动安装**
2. 上传对应架构的 `.fpk` 文件
3. 按向导完成安装（默认 API 端口 `8317`，管理面板端口 `18317`）
4. **保存安装向导中显示的密钥**（CPA 管理密钥、面板登录密钥、API Key）
5. 安装后在应用文件目录编辑 `config.yaml`，完成 OAuth 登录

## 管理面板

安装完成后访问：

```
http://<NAS_IP>:18317/management.html
```

使用安装时生成的 **面板登录密钥** 登录（不是 CPA 管理密钥）。

面板功能包括：

- 请求监控（TPS、延迟、缓存 token、失败分析）
- 模型定价与费用估算（LiteLLM 同步）
- 账户/模型/渠道/API Key 维度统计
- SQLite 持久化，重启不丢历史数据

## 数据目录（可直接编辑）

安装后配置文件位于飞牛应用文件共享目录，通常在：

```
/vol1/@appshare/CLIProxyAPI/
```

可在「文件管理」→「应用文件」→「CLIProxyAPI」中找到并编辑：

| 文件/目录 | 说明 |
|-----------|------|
| `config.yaml` | 主配置文件（API 端口、管理密钥、api-keys） |
| `config.example.yaml` | 完整配置参考 |
| `安装密钥.txt` / `CREDENTIALS.txt` | 安装密钥备份 |
| `README.txt` | 目录说明 |
| `auths/` | OAuth 认证数据 |
| `logs/` | 运行日志 |
| `service.log` | 服务框架日志 |

CPA-Manager-Plus 统计数据位于应用内部数据目录：

```
<应用数据>/manager-data/usage.sqlite
```

## 重新构建

需要 WSL 或 Linux 环境（需 `python3-pil` 或 `imagemagick` 以生成应用图标）：

```bash
git clone https://github.com/E7G/cliproxyapi-fnos.git
cd cliproxyapi-fnos
chmod +x build.sh pack-fpk.sh scripts/*.sh
./build.sh
```

构建流程会自动：

1. 生成 CLIProxyAPI 图标（绿色「CP」标识，替换旧 qBittorrent 模板占位图）
2. 为本次 fpk 生成唯一安装向导密钥（写入 `fnos/wizard/install`，勿提交 Git）
3. 下载上游二进制并打包 `dist/*.fpk`

构建时会自动下载：

- CLIProxyAPI Plus `7.1.45-0`（linux_amd64）
- CPA-Manager-Plus `1.2.1`（linux_amd64）

GitHub 下载默认依次尝试 `ghfast.top`、`mirror.ghproxy.com`、`gh-proxy.com`，失败后再直连 GitHub。

指定镜像站：

```bash
GH_MIRROR=https://ghfast.top ./build.sh
```

强制直连 GitHub（不使用镜像）：

```bash
GH_MIRROR=direct ./build.sh
```

## 应用中心图标仍显示 qBittorrent？

若从旧模板升级后图标未刷新：

1. 重新构建并安装最新 `.fpk`（`ICON.PNG` 已改为 256×256 的 CP 图标）
2. 安装/升级后脚本会自动覆盖 `/var/apps/cliproxyapi/ICON.PNG`
3. 若仍异常，在 NAS 上重启应用或重新安装一次

## 说明

- 默认 API 端口：`8317`
- 默认管理面板端口：`18317`
- 默认启用 `usage-statistics-enabled: true` 与 `redis-usage-queue-retention-seconds: 300`
- OAuth 回调等额外端口需在 `config.yaml` 中配置，并在防火墙/端口转发中放行
- CPA 管理文档：https://help.router-for.me/
- Plus 项目：https://github.com/kaitranntt/CLIProxyAPIPlus
- 面板项目：https://github.com/seakee/CPA-Manager-Plus
