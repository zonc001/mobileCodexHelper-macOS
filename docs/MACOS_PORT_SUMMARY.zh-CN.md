# mobileCodexHelper macOS 版总结

## 一句话定位

我们基于原始的 `mobileCodexHelper` Windows 方案，补齐并落地了一套 **可在 macOS 上本地运行、局域网访问、Tailscale 远程访问、并支持新设备审批的移动 Codex 控制面板方案**。

它的核心目标没有变：

- 在电脑上运行 Codex
- 在手机上查看项目 / 会话 / 消息
- 在手机上继续发消息，让电脑上的 Codex 接着执行
- 保持单用户、私有化、设备审批的安全边界

## 我们做了什么

原项目的公开仓库主要偏向：

- Windows 10 / 11
- PowerShell 编排
- nginx for Windows
- Windows 桌面控制器

在这次改造中，我们没有试图硬搬 Windows GUI，而是围绕 macOS 的真实使用场景，补出了一条更自然的链路：

- 保留上游 `claudecodeui v1.25.2`
- 保留 `mobileCodexHelper` 的 hardened mode、单用户认证、trusted devices、首次设备审批能力
- 新增 macOS 本地运行脚本
- 新增 macOS 远程启动脚本
- 新增命令行设备审批工具
- 新增可双击使用的 `.command` 文件
- 新增 macOS 中文部署说明

## 当前 macOS 版本具备的能力

### 1. 本地运行

支持在 macOS 上直接启动本地 Web 面板：

- `http://127.0.0.1:3001`

并把运行时状态固定落到仓库内：

- 数据库：`.runtime/macos/auth.db`
- 日志：`.runtime/macos/logs/`

这比依赖默认的 `~/.cloudcli/auth.db` 更可控，也更适合调试和迁移。

### 2. 局域网访问

当服务监听 `0.0.0.0` 时，手机可通过局域网 IP 访问。

这适合：

- 家中同 Wi-Fi 调试
- 办公室同网段访问
- 不依赖额外远程网络工具的场景

### 3. Tailscale 远程访问

这是 macOS 版最实用的增强之一。

我们验证了：

- Mac 与 iPhone 可加入同一 Tailnet
- `tailscale serve` 可将 `http://127.0.0.1:3001` 安全发布为 tailnet 内 HTTPS 地址
- 手机端在外网环境下，只要 Tailscale 已连接，也能远程访问 Codex 面板

这使它真正具备了“离开局域网也能继续用”的能力。

### 4. 新设备审批

原始项目里，首次设备批准主要由 Windows 桌面控制器承载。

在 macOS 版中，我们补了命令行审批工具：

- `python3 ./scripts/device-approval-cli.py list`
- `python3 ./scripts/device-approval-cli.py approve <request_token>`
- `python3 ./scripts/device-approval-cli.py reject <request_token>`

这让 macOS 不依赖 Windows GUI 也能保留原项目最重要的安全边界：

- 新设备首次登录必须人工批准
- 已批准设备进入白名单
- 单用户私有化控制逻辑不变

### 5. 一键使用

为了让它更接近真实产品而不是“只有作者自己会用的脚本集合”，我们额外补了：

- 一键启动远程服务脚本
- 一键停止远程服务脚本
- 状态查看脚本
- Finder 可双击执行的 `.command` 文件

对应入口包括：

- `./scripts/start-mobile-codex-remote-macos.sh`
- `./scripts/stop-mobile-codex-remote-macos.sh`
- `Start Mobile Codex Remote.command`
- `Stop Mobile Codex Remote.command`
- `Mobile Codex Status.command`
- `List Pending Device Approvals.command`

## 这次改造的价值

如果把它作为一个独立 GitHub 仓库或分支发布，价值主要在这几点：

### 1. 把项目从“Windows 专属”扩展成“macOS 可用”

这不是简单改几个命令，而是把原项目真正拉通到了：

- 安装
- 启动
- 登录
- 审批
- 远程访问

这一整条用户链路。

### 2. 保持了原项目的安全设计

我们没有为了“先跑起来”而破坏原项目的安全边界，反而尽量保留了它的核心原则：

- 单用户模式
- 首次新设备审批
- trusted devices
- hardened mode
- 不直接裸暴露高风险接口

### 3. 更适合个人长期私有使用

macOS 用户常见的真实诉求是：

- 电脑上跑 Codex
- 手机远程看结果、补一句话、继续跑
- 尽量少折腾
- 尽量不要把本地 agent 面板直接暴露公网

这次改造后的形态，已经比较贴近这个目标。

## 和 Windows 原版相比，macOS 版的策略差异

我们没有照搬 Windows 桌面控制器，而是做了取舍：

### 保留的部分

- 上游 Web UI
- 认证数据库
- 设备审批机制
- 项目 / 会话 / 消息能力
- Tailscale 远程思路

### 替代的部分

- 用 shell 脚本替代 PowerShell 编排
- 用命令行审批替代 Windows 桌面审批面板
- 用 `.command` 文件替代 Windows 双击启动体验

### 暂未迁移的部分

- Windows 桌面 GUI 控制台本身
- Windows nginx 编排方案
- 面向 Windows 的打包与便携发布流程

## 适合如何发布

如果准备发到 GitHub，我建议有两种路线：

### 方案 A：在当前仓库继续演化

适合：

- 你想保留与原项目的强关联
- 想把 macOS 支持作为官方补充

建议方式：

- README 增加平台说明
- docs 中区分 Windows / macOS
- 脚本按平台拆分

### 方案 B：单独发布一个 macOS 版仓库

适合：

- 你想把它定位得更清楚
- 你希望用户一眼知道这是“macOS 版”
- 你后续可能继续加 LaunchAgent、菜单栏状态、原生 GUI 等功能

可考虑的仓库名示例：

- `mobileCodexHelper-macos`
- `mobileCodexHelper-mac`
- `mobileCodexHelper-apple`
- `mobileCodexPanel-macos`

我个人更推荐：

- `mobileCodexHelper-macos`

因为它和原项目的关系最清楚。

## 当前版本适合作为 GitHub 仓库发布的原因

从工程完整性上看，它已经不是“一个想法”了，而是具备这些要素：

- 有明确定位
- 有可运行代码
- 有平台适配脚本
- 有远程访问方案
- 有设备审批工具
- 有用户文档
- 有双击入口

这已经足以作为一个公开仓库发布，并说明：

- 这是基于 Windows 版 `mobileCodexHelper` 演化出的 macOS 方案
- 目标用户是希望在 Mac 上运行 Codex，并从手机远程控制的个人用户

## 后续还可以继续补的方向

如果后续还要继续打磨，这几个方向价值最高：

### 1. 更原生的 macOS 体验

例如：

- LaunchAgent 开机自启
- 菜单栏状态图标
- 本地状态窗口
- 一键复制远程地址

### 2. 审批体验升级

当前已可用，但仍是 CLI 风格。

后续可以考虑：

- 本地 Web 审批页
- 小型 macOS 原生窗口
- menubar 审批提醒

### 3. 远程模式自动化

例如：

- 一键启动本地服务 + Tailscale Serve
- 检测当前 Serve 地址
- 自动输出“手机访问地址”

这部分我们已经做了初版，还可以继续精炼。

## 总结

可以把这次成果理解成：

> 我们不是简单地把 `mobileCodexHelper` 从 Windows 搬到 macOS，
> 而是把它重新整理成了一套更适合 macOS 用户长期私有使用的移动 Codex 控制方案。

如果作为 GitHub 仓库发布，这个版本已经有足够明确的价值主张：

- **基于 mobileCodexHelper 的 macOS 版本**
- **支持本地 / 局域网 / Tailscale 远程访问**
- **保留首次设备审批与单用户私有安全边界**
- **适合作为个人移动 Codex 控制面板长期使用**
