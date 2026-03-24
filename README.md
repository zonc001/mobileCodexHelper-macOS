# mobileCodexHelper-macos

![Platform](https://img.shields.io/badge/platform-macOS-black)
![Remote Access](https://img.shields.io/badge/remote-Tailscale%20%7C%20LAN-0ea5e9)
![Security](https://img.shields.io/badge/security-device%20approval%20enabled-16a34a)
![Mode](https://img.shields.io/badge/mode-single--user-orange)

这是一个基于原始 `mobileCodexHelper` Windows 思路演化出的 macOS 版本。它让你在 Mac 上运行本地 Codex，并通过手机浏览器在局域网或 Tailscale 私网中继续查看会话、发送消息和控制执行，同时保留首次设备审批与单用户私有安全边界。

把你 Mac 上本地运行的 Codex，会话化成一个可以在手机上访问和继续控制的私有网页面板。

这是基于原始 `mobileCodexHelper` Windows 方案演化出来的 **macOS 版本**。  
它保留了原项目最重要的能力边界：

- 单用户私有使用
- 首次新设备登录需人工批准
- 已批准设备进入白名单
- 手机主要负责“查看和聊天控制”
- 远程访问优先通过 Tailscale，而不是直接公网暴露

---

## 适合谁

这个项目适合下面这类使用场景：

- 你平时在 Mac 上跑 Codex
- 你想在手机上随时查看项目、会话、消息
- 你想在手机上继续发消息，让电脑上的 Codex 接着执行
- 你希望默认是私有访问，而不是把本地 agent 面板直接暴露出去
- 你希望新手机第一次登录时，必须经过电脑端批准

---

## 它能做什么

- 在手机浏览器中查看 Codex 项目和会话
- 在手机上发送消息，继续控制电脑上的 Codex
- 首次登录新设备时，要求电脑端人工批准
- 支持 Tailscale 远程访问
- 支持局域网访问
- 支持 macOS 本地一键启动 / 停止 / 状态查看

---

## 它不能做什么

- 不是远程桌面
- 不是完整 IDE
- 不适合多人共享使用
- 不建议直接暴露到公网
- 当前不是原生 macOS GUI App，而是 Web 面板 + shell / `.command` 启动方案

---

## 架构思路

推荐链路：

```text
手机浏览器
   ↓
Tailscale 私网 HTTPS
   ↓
本机 mobileCodexHelper Web 面板
   ↓
本地 Codex 会话
```

如果你只是在同一 Wi-Fi 下使用，也可以先走局域网访问。

---

## 当前 macOS 版本包含什么

这个仓库已经补齐了 macOS 使用链路：

- macOS 本地启动脚本
- macOS 停止脚本
- macOS 状态脚本
- Tailscale 一键远程启动脚本
- Tailscale 一键远程停止脚本
- 命令行设备审批工具
- Finder 可双击执行的 `.command` 文件
- 中文 macOS 部署说明

运行时数据默认落在仓库内：

- 数据库：`.runtime/macos/auth.db`
- 日志：`.runtime/macos/logs/`

---

## 依赖要求

至少需要：

- macOS
- Node.js
- Git
- 一个可正常使用的 Codex 本地环境

如果你要跨网络远程访问，推荐再安装：

- Tailscale

---

## 最快开始

### 1. 克隆仓库

```bash
git clone <your-repo-url>
cd mobileCodexHelper-macos
```

### 2. 准备上游 `claudecodeui`

当前版本基于：

- `siteboon/claudecodeui`
- 版本：`v1.25.2`

放到：

```text
vendor/claudecodeui-1.25.2
```

然后应用 override，并安装依赖、构建。

如果你是直接使用已经整理好的仓库版本，这一步通常已经包含在仓库内容中。

### 3. 启动本地服务

```bash
./scripts/start-mobile-codex-macos.sh
```

### 4. 打开本地面板

在 Mac 浏览器打开：

```text
http://127.0.0.1:3001
```

首次进入时完成注册。

### 5. 开启远程访问

```bash
./scripts/start-mobile-codex-remote-macos.sh
```

启动后会直接打印：

```text
Phone URL: https://...
```

手机端只要连着同一个 Tailnet，就可以打开这条地址。

---

## 常用命令

### 本地启动

```bash
./scripts/start-mobile-codex-macos.sh
```

### 本地停止

```bash
./scripts/stop-mobile-codex-macos.sh
```

### 查看状态

```bash
./scripts/status-mobile-codex-macos.sh
```

### 一键启动远程访问

```bash
./scripts/start-mobile-codex-remote-macos.sh
```

### 一键关闭远程访问

```bash
./scripts/stop-mobile-codex-remote-macos.sh
```

### 查看待审批设备

```bash
python3 ./scripts/device-approval-cli.py list
```

### 批准新设备

```bash
python3 ./scripts/device-approval-cli.py approve <request_token>
```

### 拒绝新设备

```bash
python3 ./scripts/device-approval-cli.py reject <request_token>
```

---

## 双击使用

如果你不想记命令，项目根目录也提供了可双击运行的 macOS `.command` 文件：

- `Start Mobile Codex Remote.command`
- `Stop Mobile Codex Remote.command`
- `Mobile Codex Status.command`
- `List Pending Device Approvals.command`

---

## 首次设备批准

这是这个项目最重要的安全机制之一。

当一个新手机或新浏览器第一次登录时：

1. 手机端会提示“等待电脑批准”
2. 你在 Mac 上执行：

```bash
python3 ./scripts/device-approval-cli.py list
```

3. 找到对应的 `request_token`
4. 执行：

```bash
python3 ./scripts/device-approval-cli.py approve <request_token>
```

5. 手机端自动继续登录，或重新点一次登录

---

## 远程访问建议

### 推荐方案：Tailscale

最推荐，也是这个项目最适合的远程方式：

- 不直接公网暴露服务
- 只让你自己的设备加入同一个 Tailnet
- 手机与 Mac 之间通过私网 HTTPS 访问

### 不推荐方案：公网直暴露

不建议：

- 直接开公网端口
- 直接把本地 agent 面板暴露出去

如果你一定要走公网，请至少自己额外补：

- HTTPS
- 访问控制
- 额外鉴权
- 反代与限流

---

## 这个仓库相对原 Windows 版的差异

保留：

- hardened mode
- 单用户模式
- trusted devices
- 首次设备审批
- 项目 / 会话 / 消息能力

新增：

- macOS 启停脚本
- macOS 远程脚本
- CLI 审批工具
- `.command` 双击入口
- macOS 中文文档

未迁移：

- Windows 桌面 GUI 控制台
- Windows nginx 编排
- Windows 便携打包流程

---

## 项目价值

这个仓库的价值不在于“把网页从电脑搬到手机”，而在于：

- 让本地高权限 Codex 保持在 Mac 上运行
- 让手机只承担“查看与聊天控制”
- 保留私有化与设备审批的安全边界
- 让个人用户在离开电脑时，依然可以低摩擦地继续使用 Codex

---

## 后续可以继续演进的方向

- LaunchAgent 开机自启
- 菜单栏状态图标
- 本地审批页面
- 原生 macOS GUI 封装
- 一键复制远程地址
- 更完整的发布包

---

## 文档

- macOS 版总结：`docs/MACOS_PORT_SUMMARY.zh-CN.md`
- macOS 部署说明：`docs/DEPLOYMENT.macos.zh-CN.md`

---

## 致谢

本项目基于原始 `mobileCodexHelper` Windows 方案继续演化，  
核心思路仍然来自原项目：

- 不直接暴露高权限本地 Codex
- 保持单用户私有面板
- 把手机控制能力收敛为更安全、更可控的范围
