# 🤖 AI Coding Agents Headless Manager

> **一键安装、无头配置、守护进程、健康检查、远程管理**
> 适配 OpenCode、Claude Code、Cursor Agent、Codex CLI、Windsurf、Gemini CLI、Aider、Kilo Code、Copilot CLI 等主流 AI 编码代理

---

## 技能名称
`coding-agents-headless`

## 技能描述
在 Mac mini / 服务器上自动安装、配置、守护主流 AI 编码代理，实现无显示器 7×24 小时无头运行。支持一键安装多个代理、自动生成 LaunchAgent 守护进程、健康检查与自动恢复、Tailscale 外网穿透远程管理。

## 触发关键词
- `安装 AI 编码代理`
- `配置无头运行`
- `管理 coding agent`
- `AI 代理守护进程`
- `coding agent 健康检查`
- `headless coding agent`
- `安装 opencode`
- `安装 claude code`
- `安装 aider`
- `安装 codex cli`
- `安装 kilo code`

## 环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `AGENTS_HOME` | 代理安装根目录 | `~/.coding-agents` |
| `AGENTS_LOG_DIR` | 日志目录 | `~/.coding-agents/logs` |
| `AGENTS_CONFIG_DIR` | 配置目录 | `~/.coding-agents/config` |
| `TAILSCALE_ENABLED` | 是否启用 Tailscale | `false` |
| `HEALTHCHECK_INTERVAL` | 健康检查间隔（分钟） | `5` |
| `DISK_WARN_PERCENT` | 磁盘告警阈值 | `90` |
| `ALERT_EMAIL` | 告警邮箱（可选） | 空 |

## 支持的 AI 编码代理

| 代理 | 安装方式 | CLI 命令 | 无头模式 | 守护进程 |
|------|----------|----------|----------|----------|
| **OpenCode** | npm / go install | `opencode` | ✅ | ✅ |
| **Claude Code** | npm | `claude` | ✅ `--print` | ✅ |
| **Codex CLI** | npm | `codex` | ✅ `--quiet` | ✅ |
| **Gemini CLI** | npm | `gemini` | ✅ | ✅ |
| **Aider** | pip | `aider` | ✅ `--no-auto-commits` | ✅ |
| **Kilo Code** | npm / VS Code 扩展 | `kilo-code` | ✅ `--non-interactive` | ✅ |
| **Cursor Agent** | 应用内置 | `cursor` | ⚠️ 需 VNC | ✅ |
| **Windsurf** | 应用内置 | `windsurf` | ⚠️ 需 VNC | ✅ |
| **GitHub Copilot CLI** | npm | `gh copilot` | ✅ | ✅ |

## 操作流程

当用户触发此技能时，按以下流程执行：

### 流程 1: 一键安装代理

```
用户: "帮我安装 OpenCode 和 Claude Code，配置无头运行"

1. 检查系统环境 (macOS/Linux, Node.js, Python, 磁盘空间)
2. 安装指定的 AI 编码代理
   - OpenCode:  go install / npm install -g opencode
   - Claude Code: npm install -g @anthropic/claude-code
   - Codex CLI:  npm install -g @openai/codex
   - Gemini CLI: npm install -g @anthropic-ai/gemini-cli
   - Aider:      pip install aider-chat
3. 配置电源管理 (pmset / systemd)
4. 配置 SSH + VNC 远程访问
5. 生成 LaunchAgent / systemd 守护进程
6. 设置健康检查 cron
7. 输出验证报告
```

### 流程 2: 管理已安装代理

```
用户: "查看所有 AI 编码代理状态"

1. 扫描已安装的代理
2. 检查每个代理的运行状态
3. 检查端口占用
4. 显示资源占用 (CPU/内存)
5. 输出状态报告
```

### 流程 3: 健康检查

```
用户: "检查 AI 代理健康状态" / cron 自动触发

1. 检查每个代理进程是否存在
2. 检查端口是否正常监听
3. 检查磁盘空间
4. 检查内存使用
5. 异常时自动重启 + 告警
6. 记录日志
```

### 流程 4: 远程管理

```
用户: "远程连接到 Mac mini 上的 AI 代理"

1. 检查 Tailscale 状态
2. 获取 100.x 地址
3. 建立 SSH 隧道
4. 代理命令转发
```

## 使用示例

### 示例 1: 安装单个代理
```
用户: "帮我安装 Claude Code 并配置无头运行"
→ 执行 install-coding-agents.sh --agents claude-code --headless
```

### 示例 2: 安装多个代理
```
用户: "把 OpenCode、Claude Code 和 Aider 都装上，配好守护进程"
→ 执行 install-coding-agents.sh --agents opencode,claude-code,aider --daemon
```

### 示例 3: 查看状态
```
用户: "所有 AI 编码代理运行正常吗？"
→ 执行 manage-agents.sh status
```

### 示例 4: 健康检查
```
用户: "检查 AI 代理健康状态"
→ 执行 agents-healthcheck.sh
```

### 示例 5: 全套配置
```
用户: "新买了一台 Mac mini，帮我配成 AI 编码服务器"
→ 执行 install-coding-agents.sh --full-setup
   (安装所有代理 + 电源管理 + SSH + VNC + Tailscale + 守护进程 + 健康检查)
```

## 核心脚本说明

### scripts/install-coding-agents.sh
主安装脚本，支持以下参数：
- `--agents <list>` — 指定要安装的代理（逗号分隔）
- `--all` — 安装所有支持的代理
- `--headless` — 配置无头运行（电源管理 + SSH + VNC）
- `--daemon` — 生成 LaunchAgent 守护进程
- `--healthcheck` — 设置健康检查 cron
- `--tailscale` — 安装配置 Tailscale
- `--full-setup` — 全套配置（等于以上全部）
- `--list` — 列出所有支持的代理

### scripts/manage-agents.sh
管理脚本，支持以下命令：
- `status` — 查看所有代理状态
- `start <agent>` — 启动指定代理
- `stop <agent>` — 停止指定代理
- `restart <agent>` — 重启指定代理
- `logs <agent>` — 查看代理日志
- `list` — 列出已安装的代理

### scripts/agents-healthcheck.sh
健康检查脚本（由 cron 定期调用）：
- 进程存在性检查
- 端口监听检查
- 磁盘空间检查
- 内存使用检查
- 自动重启 + 告警

## 注意事项

1. **首次配置需要显示器**：SSH、VNC、Tailscale 登录需要交互式操作
2. **API Key 配置**：各代理的 API Key 需要用户自行配置（脚本会提示）
3. **Claude Code 无头模式**：使用 `claude --print` 或 `claude -p` 进行非交互式调用
4. **Cursor/Windsurf**：这些是 GUI 应用，无头运行需要 VNC 远程桌面
5. **资源规划**：建议 Mac mini 16GB+ 内存，同时运行多个代理需要更多资源
6. **安全建议**：使用 SSH 密钥认证、Tailscale Shields Up、限制代理文件访问权限
