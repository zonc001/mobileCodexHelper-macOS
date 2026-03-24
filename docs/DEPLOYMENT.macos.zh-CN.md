# macOS 本地运行说明

这份说明只覆盖 **macOS 本机运行**。

它的目标不是复刻 README 里的 Windows 桌面控制台，而是先在 Mac 上把「手机可查看、可登录、可继续控制本地 Codex」这条主链跑通。

## 先说结论

这个仓库在 macOS 上最稳的使用方式是：

- 继续使用本项目的 hardened Web 服务
- 暂时不依赖 Windows 专属的桌面控制器
- 暂时不依赖 PowerShell 编排脚本
- 先把本机地址 `http://127.0.0.1:3001` 跑通
- 之后再按你的网络方案决定是否接入 Tailscale / Caddy / nginx

## 当前 macOS 方案包含什么

可用：

- 上游 `claudecodeui v1.25.2`
- 本项目的设备审批 / trusted devices 补丁
- 本地 SQLite 认证库
- `Codex-only hardened mode`
- macOS 启动 / 停止 / 状态脚本

不包含：

- Windows 桌面 GUI 控制器
- `nginx for Windows`
- PowerShell 启停脚本
- README 中那套 Windows 首次初始化向导

## 目录约定

本方案默认使用：

- 上游目录：`vendor/claudecodeui-1.25.2`
- 运行时目录：`.runtime/macos/`
- 数据库：`.runtime/macos/auth.db`
- 日志：
  - `.runtime/macos/logs/mobile-codex.stdout.log`
  - `.runtime/macos/logs/mobile-codex.stderr.log`

这样做的好处是：

- 所有运行状态都留在仓库内
- 不依赖 `~/.cloudcli/auth.db`
- 更适合本地调试和迁移

## 启动前要求

至少需要：

- Node.js
- 已完成 `npm install`
- 已完成 `npm run build`
- 本机已有可用的 Codex CLI 环境

如果你是直接使用当前仓库，并且已经完成安装，通常只需要启动脚本即可。

## 常用命令

启动：

```bash
./scripts/start-mobile-codex-macos.sh
```

一键启动本地服务并开启 Tailscale 远程访问：

```bash
./scripts/start-mobile-codex-remote-macos.sh
```

执行后会自动打印：

- 本地服务是否已启动
- Tailscale Serve 是否已开启
- 一行可直接给手机使用的 `Phone URL: ...`

如果你不想记命令，也可以直接双击项目根目录里的这些文件：

- `Start Mobile Codex Remote.command`
- `Stop Mobile Codex Remote.command`
- `Mobile Codex Status.command`
- `List Pending Device Approvals.command`

停止：

```bash
./scripts/stop-mobile-codex-macos.sh
```

一键关闭 Tailscale 远程访问并停止本地服务：

```bash
./scripts/stop-mobile-codex-remote-macos.sh
```

查看状态：

```bash
./scripts/status-mobile-codex-macos.sh
```

查看待审批设备：

```bash
python3 ./scripts/device-approval-cli.py list
```

批准设备：

```bash
python3 ./scripts/device-approval-cli.py approve <request_token>
```

拒绝设备：

```bash
python3 ./scripts/device-approval-cli.py reject <request_token>
```

## 成功标准

满足下面这些，说明 macOS 本地链路已经通了：

- `./scripts/start-mobile-codex-macos.sh` 成功返回
- 浏览器可打开 `http://127.0.0.1:3001`
- `./scripts/status-mobile-codex-macos.sh` 显示 `Health: ok`
- 首次注册可以完成
- 登录后能看到 Codex 项目 / 会话
- 新设备登录时，可以用命令行审批并完成二次登录

## 远程访问建议

先本地跑通，再考虑远程。

在 macOS 上，更建议你后续选择下面两类方案之一：

1. Tailscale + Tailscale Serve
2. Tailscale + Caddy / nginx 反代

不建议一开始就直接公网暴露 `3001`。

## 当前已知限制

- 本仓库的桌面控制器主要面向 Windows，macOS 下不等价
- README 里的 GUI 审批体验，在 macOS 下目前没有同款封装
- 如果你后续要做“手机私有 HTTPS 地址”，还需要额外补一层隧道或反代

## 排障顺序

如果打不开，按这个顺序查：

1. 先看 `./scripts/status-mobile-codex-macos.sh`
2. 再看 `.runtime/macos/logs/mobile-codex.stderr.log`
3. 确认 `vendor/claudecodeui-1.25.2/node_modules/` 存在
4. 确认 `vendor/claudecodeui-1.25.2/dist/index.html` 存在
5. 确认本机 `codex` CLI 可正常使用
