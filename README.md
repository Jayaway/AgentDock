# 🤖 AI Coding Agents 无头管理器

> 一键安装、无头配置、守护进程、健康检查、远程管理
> 适配 8 大主流 AI 编码代理

## 支持的代理

| 代理 | 类型 | 无头模式 | 安装方式 |
|------|------|----------|----------|
| **OpenCode** | CLI | ✅ 原生 | `npm install -g opencode` |
| **Claude Code** | CLI | ✅ `--print` | `npm install -g @anthropic/claude-code` |
| **Codex CLI** | CLI | ✅ `--quiet` | `npm install -g @openai/codex` |
| **Gemini CLI** | CLI | ✅ | `npm install -g @anthropic-ai/gemini-cli` |
| **Aider** | CLI | ✅ | `pip install aider-chat` |
| **Copilot CLI** | CLI | ✅ | `npm install -g @githubnext/gh-copilot` |
| **Cursor** | GUI | ⚠️ 需 VNC | `brew install --cask cursor` |
| **Windsurf** | GUI | ⚠️ 需 VNC | `brew install --cask windsurf` |

## 快速开始

### 安装到 OpenClaw

```bash
npx clawhub@latest install coding-agents-headless
```

### 全套配置（推荐）

```bash
# 在 OpenClaw 中发送:
"帮我做全套配置，安装 OpenCode 和 Claude Code"
```

或直接运行脚本:

```bash
bash scripts/install-coding-agents.sh --agents opencode,claude-code --full-setup
```

### 仅安装代理

```bash
# 安装单个
bash scripts/install-coding-agents.sh --agents claude-code

# 安装全部
bash scripts/install-coding-agents.sh --all
```

### 管理代理

```bash
bash scripts/manage-agents.sh status     # 查看状态
bash scripts/manage-agents.sh list       # 列出已安装
bash scripts/manage-agents.sh start claude-code
bash scripts/manage-agents.sh stop claude-code
bash scripts/manage-agents.sh restart claude-code
bash scripts/manage-agents.sh logs claude-code
```

## 文件结构

```
coding-agents-headless/
├── SKILL.md                              # 技能配置（AI 读取的操作手册）
├── skill.json                            # 技能元信息
├── README.md                             # 说明文档
├── package.json                          # Node.js 模块配置
└── scripts/
    ├── install-coding-agents.sh          # 主安装脚本
    ├── manage-agents.sh                  # 代理管理脚本
    └── agents-healthcheck.sh             # 健康检查脚本
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `AGENTS_HOME` | `~/.coding-agents` | 代理安装根目录 |
| `AGENTS_LOG_DIR` | `~/.coding-agents/logs` | 日志目录 |
| `HEALTHCHECK_INTERVAL` | `5` | 健康检查间隔（分钟） |
| `DISK_WARN_PERCENT` | `90` | 磁盘告警阈值 |
| `ALERT_EMAIL` | 空 | 告警邮箱 |

## 安装脚本参数

```
--agents <list>     指定代理（逗号分隔）
--all               安装所有代理
--headless          配置无头运行
--daemon            生成守护进程
--healthcheck       设置健康检查 cron
--tailscale         安装 Tailscale
--full-setup        全套配置
--list              列出支持的代理
```

## 许可证

MIT License
