#!/bin/bash
# ============================================================
#  AI Coding Agents 无头管理器 - 安装脚本
#  适配 OpenCode / Claude Code / Codex CLI / Gemini CLI / Aider
#       Cursor / Windsurf / Copilot CLI
# ============================================================
set -uo pipefail

VERSION="1.0.0"
AGENTS_HOME="${AGENTS_HOME:-$HOME/.coding-agents}"
AGENTS_LOG_DIR="${AGENTS_LOG_DIR:-$HOME/.coding-agents/logs}"
AGENTS_CONFIG_DIR="${AGENTS_CONFIG_DIR:-$HOME/.coding-agents/config}"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# 颜色
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log_info()  { echo -e "${GREEN}[✓]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[!]${NC}  $*"; }
log_error() { echo -e "${RED}[✗]${NC}  $*"; }
log_step()  { echo -e "\n${BLUE}${BOLD}[$1]${NC} $2"; }
log_detail(){ echo -e "    ${CYAN}→${NC} $*"; }

# ==================== 代理定义 ====================
declare -A AGENT_INSTALL_CMD
declare -A AGENT_CHECK_CMD
declare -A AGENT_DESC
declare -A AGENT_HEADLESS_CMD
declare -A AGENT_PORT
declare -A AGENT_CONFIG_HINT

# --- OpenCode ---
AGENT_INSTALL_CMD[opencode]="npm install -g opencode"
AGENT_CHECK_CMD[opencode]="opencode --version"
AGENT_DESC[opencode]="开源 AI 编码助手，支持 75+ 大模型"
AGENT_HEADLESS_CMD[opencode]="opencode --non-interactive"
AGENT_PORT[opencode]=""
AGENT_CONFIG_HINT[opencode]="配置: opencode config set model <model>"

# --- Claude Code ---
AGENT_INSTALL_CMD[claude-code]="npm install -g @anthropic/claude-code"
AGENT_CHECK_CMD[claude-code]="claude --version"
AGENT_DESC[claude-code]="Anthropic Claude 编码代理"
AGENT_HEADLESS_CMD[claude-code]="claude -p"
AGENT_PORT[claude-code]=""
AGENT_CONFIG_HINT[claude-code]="配置: export ANTHROPIC_API_KEY=sk-ant-..."

# --- Codex CLI ---
AGENT_INSTALL_CMD[codex-cli]="npm install -g @openai/codex"
AGENT_CHECK_CMD[codex-cli]="codex --version"
AGENT_DESC[codex-cli]="OpenAI Codex 命令行编码代理"
AGENT_HEADLESS_CMD[codex-cli]="codex --quiet"
AGENT_PORT[codex-cli]=""
AGENT_CONFIG_HINT[codex-cli]="配置: export OPENAI_API_KEY=sk-..."

# --- Gemini CLI ---
AGENT_INSTALL_CMD[gemini-cli]="npm install -g @anthropic-ai/gemini-cli"
AGENT_CHECK_CMD[gemini-cli]="gemini --version"
AGENT_DESC[gemini-cli]="Google Gemini 命令行工具"
AGENT_HEADLESS_CMD[gemini-cli]="gemini --non-interactive"
AGENT_PORT[gemini-cli]=""
AGENT_CONFIG_HINT[gemini-cli]="配置: export GEMINI_API_KEY=..."

# --- Aider ---
AGENT_INSTALL_CMD[aider]="pip install aider-chat"
AGENT_CHECK_CMD[aider]="aider --version"
AGENT_DESC[aider]="AI 结对编程助手，支持多种模型"
AGENT_HEADLESS_CMD[aider]="aider --no-auto-commits --yes"
AGENT_PORT[aider]=""
AGENT_CONFIG_HINT[aider]="配置: export OPENAI_API_KEY=... 或 aider --model <model>"

# --- Cursor (GUI) ---
AGENT_INSTALL_CMD[cursor]="brew install --cask cursor"
AGENT_CHECK_CMD[cursor]="ls /Applications/Cursor.app"
AGENT_DESC[cursor]="Cursor AI 编辑器（GUI，需 VNC 远程）"
AGENT_HEADLESS_CMD[cursor]="open -a Cursor"
AGENT_PORT[cursor]=""
AGENT_CONFIG_HINT[cursor]="GUI 应用，需通过 VNC 远程桌面操作"

# --- Windsurf (GUI) ---
AGENT_INSTALL_CMD[windsurf]="brew install --cask windsurf"
AGENT_CHECK_CMD[windsurf]="ls /Applications/Windsurf.app"
AGENT_DESC[windsurf]="Windsurf AI 编辑器（GUI，需 VNC 远程）"
AGENT_HEADLESS_CMD[windsurf]="open -a Windsurf"
AGENT_PORT[windsurf]=""
AGENT_CONFIG_HINT[windsurf]="GUI 应用，需通过 VNC 远程桌面操作"

# --- Copilot CLI ---
AGENT_INSTALL_CMD[copilot-cli]="npm install -g @githubnext/gh-copilot"
AGENT_CHECK_CMD[copilot-cli]="gh copilot --version"
AGENT_DESC[copilot-cli]="GitHub Copilot 命令行工具"
AGENT_HEADLESS_CMD[copilot-cli]="gh copilot suggest"
AGENT_PORT[copilot-cli]=""
AGENT_CONFIG_HINT[copilot-cli]="配置: gh auth login"

# --- Kilo Code ---
AGENT_INSTALL_CMD[kilo-code]="npm install -g @kilocode/kilo-code"
AGENT_CHECK_CMD[kilo-code]="kilo-code --version"
AGENT_DESC[kilo-code]="开源 VS Code AI 编码代理，支持 400+ 模型"
AGENT_HEADLESS_CMD[kilo-code]="kilo-code --non-interactive"
AGENT_PORT[kilo-code]=""
AGENT_CONFIG_HINT[kilo-code]="配置: 在 VS Code 中安装 Kilo Code 扩展，或使用 CLI 模式"

ALL_AGENTS=("opencode" "claude-code" "codex-cli" "gemini-cli" "aider" "kilo-code" "cursor" "windsurf" "copilot-cli")

# ==================== 参数解析 ====================
INSTALL_AGENTS=()
DO_HEADLESS=false
DO_DAEMON=false
DO_HEALTHCHECK=false
DO_TAILSCALE=false
DO_FULL_SETUP=false
DO_LIST=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --agents) shift; IFS=',' read -ra INSTALL_AGENTS <<< "$1" ;;
            --all)     INSTALL_AGENTS=("${ALL_AGENTS[@]}") ;;
            --headless) DO_HEADLESS=true ;;
            --daemon)   DO_DAEMON=true ;;
            --healthcheck) DO_HEALTHCHECK=true ;;
            --tailscale) DO_TAILSCALE=true ;;
            --full-setup) DO_FULL_SETUP=true ;;
            --list)     DO_LIST=true ;;
            --help|-h)  show_help; exit 0 ;;
            *) log_error "未知参数: $1"; show_help; exit 1 ;;
        esac
        shift
    done

    if $DO_FULL_SETUP; then
        DO_HEADLESS=true; DO_DAEMON=true; DO_HEALTHCHECK=true; DO_TAILSCALE=true
        [[ ${#INSTALL_AGENTS[@]} -eq 0 ]] && INSTALL_AGENTS=("${ALL_AGENTS[@]}")
    fi
}

show_help() {
    echo "AI Coding Agents 无头管理器 v$VERSION"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --agents <list>     指定代理（逗号分隔）: opencode,claude-code,aider"
    echo "  --all               安装所有支持的代理"
    echo "  --headless          配置无头运行（电源管理 + SSH + VNC）"
    echo "  --daemon            生成 LaunchAgent 守护进程"
    echo "  --healthcheck       设置健康检查 cron"
    echo "  --tailscale         安装配置 Tailscale"
    echo "  --full-setup        全套配置（等于以上全部）"
    echo "  --list              列出所有支持的代理"
    echo "  --help              显示帮助"
    echo ""
    echo "支持的代理: ${ALL_AGENTS[*]}"
}

# ==================== 阶段 1: 环境检查 ====================
phase_check_env() {
    log_step "1" "系统环境检查"

    # OS
    local os="$(uname)"
    log_info "操作系统: $os ($(uname -m))"
    [[ "$os" != "Darwin" && "$os" != "Linux" ]] && { log_error "仅支持 macOS/Linux"; exit 1; }

    # 磁盘
    local avail
    avail=$(df -h "$HOME" | awk 'NR==2 {print $4}')
    log_info "磁盘可用: $avail"

    # Node.js
    if command -v node &>/dev/null; then
        local nv=$(node -v)
        local nm=$(echo "$nv" | sed 's/v//' | cut -d. -f1)
        log_info "Node.js: $nv"
        if [[ "$nm" -lt 18 ]]; then
            log_warn "Node.js 版本过低（建议 >= 18），部分代理可能无法安装"
        fi
    else
        log_warn "Node.js 未安装（Claude Code / Codex CLI / Gemini CLI 需要）"
        log_detail "安装: brew install node@22"
    fi

    # Python
    if command -v python3 &>/dev/null; then
        log_info "Python: $(python3 --version 2>&1)"
    else
        log_warn "Python3 未安装（Aider 需要）"
        log_detail "安装: brew install python@3.12"
    fi

    # pip
    if command -v pip3 &>/dev/null; then
        log_info "pip: $(pip3 --version 2>&1 | head -1)"
    else
        log_warn "pip3 未安装"
    fi

    # Go (OpenCode 可选)
    if command -v go &>/dev/null; then
        log_info "Go: $(go version | awk '{print $3}')"
    fi

    # brew
    if command -v brew &>/dev/null; then
        log_info "Homebrew: $(brew --version | head -1)"
    else
        log_warn "Homebrew 未安装（Cursor / Windsurf 需要）"
    fi

    # 网络
    if curl -s --connect-timeout 5 https://registry.npmjs.org/ >/dev/null 2>&1; then
        log_info "npm registry: 可达"
    else
        log_warn "npm registry 不可达，安装可能失败"
        log_detail "可配置镜像: npm config set registry https://registry.npmmirror.com"
    fi
}

# ==================== 阶段 2: 安装代理 ====================
phase_install_agents() {
    log_step "2" "安装 AI 编码代理"

    if [[ ${#INSTALL_AGENTS[@]} -eq 0 ]]; then
        log_warn "未指定要安装的代理（使用 --agents 或 --all）"
        return 0
    fi

    mkdir -p "$AGENTS_HOME" "$AGENTS_LOG_DIR" "$AGENTS_CONFIG_DIR"

    local installed=0
    local failed=0
    local skipped=0

    for agent in "${INSTALL_AGENTS[@]}"; do
        echo ""
        log_detail "━━━ ${BOLD}${AGENT_DESC[$agent]:-$agent}${NC} ━━━"

        # 检查是否已安装
        local check_cmd="${AGENT_CHECK_CMD[$agent]}"
        if [[ -n "$check_cmd" ]] && eval "$check_cmd" >/dev/null 2>&1; then
            log_info "$agent: 已安装 ($(eval "$check_cmd" 2>/dev/null | head -1))"
            skipped=$((skipped + 1))
            continue
        fi

        # 安装
        local install_cmd="${AGENT_INSTALL_CMD[$agent]}"
        log_detail "安装命令: $install_cmd"

        # 前置依赖检查
        case "$agent" in
            opencode|claude-code|codex-cli|gemini-cli|copilot-cli)
                if ! command -v node &>/dev/null; then
                    log_error "$agent 需要 Node.js，跳过"
                    failed=$((failed + 1)); continue
                fi
                ;;
            aider)
                if ! command -v pip3 &>/dev/null; then
                    log_error "$agent 需要 pip3，跳过"
                    failed=$((failed + 1)); continue
                fi
                ;;
            cursor|windsurf)
                if ! command -v brew &>/dev/null; then
                    log_error "$agent 需要 Homebrew，跳过"
                    failed=$((failed + 1)); continue
                fi
                ;;
        esac

        if eval "$install_cmd" 2>&1 | tail -3; then
            # 验证安装
            if [[ -n "$check_cmd" ]] && eval "$check_cmd" >/dev/null 2>&1; then
                log_info "$agent: 安装成功 ✅"
                [[ -n "${AGENT_CONFIG_HINT[$agent]}" ]] && log_detail "${AGENT_CONFIG_HINT[$agent]}"
                installed=$((installed + 1))
            else
                log_warn "$agent: 安装命令执行完成但验证失败，请手动检查"
                failed=$((failed + 1))
            fi
        else
            log_error "$agent: 安装失败"
            log_detail "手动安装: $install_cmd"
            failed=$((failed + 1))
        fi
    done

    echo ""
    log_info "安装结果: 成功 $installed / 跳过 $skipped / 失败 $failed"
}

# ==================== 阶段 3: 无头配置 ====================
phase_headless() {
    log_step "3" "配置无头运行环境"

    local is_mac=false
    [[ "$(uname)" == "Darwin" ]] && is_mac=true

    # --- 电源管理 ---
    log_detail "配置电源管理..."
    if $is_mac; then
        sudo pmset -a sleep 0 2>/dev/null && log_info "系统睡眠: 已禁用" || log_warn "sleep 设置失败"
        sudo pmset -a disksleep 0 2>/dev/null && log_info "磁盘休眠: 已禁用" || log_warn "disksleep 设置失败"
        sudo pmset -a displaysleep 30 2>/dev/null
        sudo pmset -a autorestart 1 2>/dev/null && log_info "断电自启: 已开启" || log_warn "autorestart 设置失败"
        sudo pmset -a womp 1 2>/dev/null && log_info "网络唤醒: 已开启" || true
        sudo pmset -a powernap 0 2>/dev/null
    else
        # Linux: 使用 systemd inhibitor
        if command -v systemctl &>/dev/null; then
            sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null
            log_info "Linux: 已禁用睡眠/休眠"
        fi
    fi

    # --- SSH ---
    log_detail "配置 SSH..."
    if $is_mac; then
        local ssh_on
        ssh_on=$(sudo systemsetup -getremotelogin 2>/dev/null | grep -o 'On\|Off')
        if [[ "$ssh_on" == "On" ]]; then
            log_info "SSH: 已开启"
        else
            sudo systemsetup -setremotelogin on 2>/dev/null && log_info "SSH: 已开启" || log_error "SSH 开启失败"
        fi
    else
        if systemctl is-active sshd >/dev/null 2>&1; then
            log_info "SSH: 已运行"
        elif sudo systemctl enable --now sshd 2>/dev/null; then
            log_info "SSH: 已开启"
        fi
    fi

    # --- VNC (macOS) ---
    if $is_mac; then
        log_detail "配置屏幕共享..."
        if sudo launchctl list 2>/dev/null | grep -q "com.apple.screensharing"; then
            log_info "屏幕共享: 已开启"
        else
            sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
                -activate -configure -access -on -users "$(whoami)" -privs -all -restart -agent 2>/dev/null
            sleep 2
            if sudo launchctl list 2>/dev/null | grep -q "com.apple.screensharing"; then
                log_info "屏幕共享: 已开启"
            else
                log_warn "屏幕共享开启失败，手动: 系统设置→通用→共享→屏幕共享"
            fi
        fi
    fi

    # --- 主机名 ---
    local hostname
    hostname=$(scutil --get LocalHostName 2>/dev/null || hostname 2>/dev/null)
    log_info "主机名: $hostname ($hostname.local)"
}

# ==================== 阶段 4: 守护进程 ====================
phase_daemon() {
    log_step "4" "配置守护进程"

    local is_mac=false
    [[ "$(uname)" == "Darwin" ]] && is_mac=true

    for agent in "${INSTALL_AGENTS[@]}"; do
        local check_cmd="${AGENT_CHECK_CMD[$agent]}"
        [[ -z "$check_cmd" ]] && continue
        eval "$check_cmd" >/dev/null 2>&1 || continue

        # 跳过 GUI 应用（无法真正无头守护）
        case "$agent" in cursor|windsurf)
            log_detail "$agent: GUI 应用，跳过守护进程（使用 VNC 远程操作）"
            continue
            ;;
        esac

        local agent_bin
        agent_bin=$(eval "${check_cmd%% *} 2>/dev/null" | head -1)
        agent_bin=$(which "${check_cmd%% *}" 2>/dev/null)
        [[ -z "$agent_bin" ]] && continue

        if $is_mac; then
            local plist="$LAUNCH_AGENT_DIR/com.codingagent.${agent}.plist"
            cat > "$plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.codingagent.${agent}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${agent_bin}</string>
        <string>--version</string>
    </array>
    <key>WorkingDirectory</key>
    <string>${AGENTS_HOME}/${agent}</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${HOME}/.local/bin</string>
        <key>HOME</key>
        <string>${HOME}</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardOutPath</key>
    <string>${AGENTS_LOG_DIR}/${agent}-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>${AGENTS_LOG_DIR}/${agent}-stderr.log</string>
</dict>
</plist>
PLIST
            plutil -lint "$plist" >/dev/null 2>&1 && log_info "$agent: LaunchAgent 已生成" || log_error "$agent: plist 格式错误"
        else
            local service_file="/etc/systemd/system/codingagent-${agent}.service"
            sudo tee "$service_file" > /dev/null << SERVICE
[Unit]
Description=Coding Agent: ${agent}
After=network.target

[Service]
Type=simple
ExecStart=${agent_bin} --version
WorkingDirectory=${AGENTS_HOME}/${agent}
Environment=PATH=/usr/local/bin:/usr/bin:/bin:${HOME}/.local/bin
Environment=HOME=${HOME}
Restart=on-failure
RestartSec=10
StandardOutput=append:${AGENTS_LOG_DIR}/${agent}-stdout.log
StandardError=append:${AGENTS_LOG_DIR}/${agent}-stderr.log

[Install]
WantedBy=multi-user.target
SERVICE
            log_info "$agent: systemd service 已生成 ($service_file)"
        fi
    done

    log_detail "注意: 守护进程模板已生成，请根据实际使用场景修改 ExecStart 命令"
    log_detail "macOS: launchctl load -w $LAUNCH_AGENT_DIR/com.codingagent.<agent>.plist"
    log_detail "Linux:  sudo systemctl enable --now codingagent-<agent>"
}

# ==================== 阶段 5: 健康检查 ====================
phase_healthcheck() {
    log_step "5" "配置健康检查"

    local healthcheck_script="$AGENTS_HOME/scripts/agents-healthcheck.sh"
    mkdir -p "$(dirname "$healthcheck_script")"

    # 复制健康检查脚本
    if [[ -f "$SKILL_DIR/scripts/agents-healthcheck.sh" ]]; then
        cp "$SKILL_DIR/scripts/agents-healthcheck.sh" "$healthcheck_script"
        chmod +x "$healthcheck_script"
    else
        # 内联生成简化版
        cat > "$healthcheck_script" << 'HC_EOF'
#!/bin/bash
# AI Coding Agents 健康检查
AGENTS_HOME="${AGENTS_HOME:-$HOME/.coding-agents}"
LOG_DIR="$AGENTS_HOME/logs"
HEALTH_LOG="$LOG_DIR/healthcheck.log"
mkdir -p "$LOG_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$HEALTH_LOG"; }

# 检查各代理
for agent_bin in opencode claude codex gemini aider gh; do
    if command -v "$agent_bin" &>/dev/null; then
        if pgrep -f "$agent_bin" >/dev/null 2>&1; then
            log "✅ $agent_bin: 运行中 (PID: $(pgrep -f "$agent_bin" | head -1))"
        else
            log "⏸️  $agent_bin: 已安装但未运行"
        fi
    fi
done

# 磁盘检查
local usage
usage=$(df -h "$HOME" | awk 'NR==2 {print $5}' | tr -d '%')
if [[ "$usage" -gt 90 ]]; then
    log "⚠️  磁盘使用率: ${usage}%"
fi

log "✅ 健康检查完成"
HC_EOF
        chmod +x "$healthcheck_script"
    fi

    # 设置 cron
    local interval="${HEALTHCHECK_INTERVAL:-5}"
    (crontab -l 2>/dev/null | grep -v "agents-healthcheck"; echo "*/${interval} * * * * $healthcheck_script >> $AGENTS_LOG_DIR/cron.log 2>&1") | crontab -
    log_info "健康检查 cron: 每 ${interval} 分钟"
}

# ==================== 阶段 6: Tailscale ====================
phase_tailscale() {
    log_step "6" "配置 Tailscale"

    if command -v tailscale &>/dev/null; then
        local ts_ip
        ts_ip=$(tailscale ip -4 2>/dev/null)
        if [[ -n "$ts_ip" ]]; then
            log_info "Tailscale: 已登录 (IP: $ts_ip)"
            return 0
        fi
    fi

    log_detail "安装 Tailscale..."
    if [[ "$(uname)" == "Darwin" ]]; then
        brew install --cask tailscale 2>/dev/null || {
            local pkg
            pkg=$(curl -fsSL "https://pkgs.tailscale.com/stable/" 2>/dev/null | grep -Eo 'Tailscale-[0-9.]+-macos\.pkg' | head -1)
            [[ -n "$pkg" ]] && curl -fL "https://pkgs.tailscale.com/stable/$pkg" -o "/tmp/$pkg" && sudo installer -pkg "/tmp/$pkg" -target /
        }
    else
        curl -fsSL https://tailscale.com/install.sh | sh
    fi

    if command -v tailscale &>/dev/null; then
        log_info "Tailscale: 已安装"
        log_detail "登录: tailscale up（会弹出浏览器授权）"
        log_detail "两台设备需登录同一账号"
    else
        log_error "Tailscale 安装失败"
    fi
}

# ==================== 阶段 7: 验证报告 ====================
phase_report() {
    log_step "7" "验证报告"

    echo ""
    echo -e "${BOLD}  📊 已安装的 AI 编码代理${NC}"
    echo -e "  ─────────────────────────────────────"

    for agent in "${ALL_AGENTS[@]}"; do
        local check_cmd="${AGENT_CHECK_CMD[$agent]}"
        local status_icon="  "
        local status_text=""

        if [[ -n "$check_cmd" ]] && eval "$check_cmd" >/dev/null 2>&1; then
            status_icon="${GREEN}✅${NC}"
            status_text="$(eval "$check_cmd" 2>/dev/null | head -1)"
        else
            status_icon="${RED}✗${NC}"
            status_text="未安装"
        fi

        printf "  %-15s %b %-30s %s\n" "$agent" "$status_icon" "${AGENT_DESC[$agent]:-}" "$status_text"
    done

    echo ""
    echo -e "${BOLD}  🔧 配置状态${NC}"
    echo -e "  ─────────────────────────────────────"

    # SSH
    if [[ "$(uname)" == "Darwin" ]]; then
        local ssh_on
        ssh_on=$(sudo systemsetup -getremotelogin 2>/dev/null | grep -o 'On\|Off')
        [[ "$ssh_on" == "On" ]] && echo -e "  SSH:           ${GREEN}✅ 已开启${NC}" || echo -e "  SSH:           ${RED}✗ 未开启${NC}"

        # VNC
        sudo launchctl list 2>/dev/null | grep -q "com.apple.screensharing" && \
            echo -e "  屏幕共享:      ${GREEN}✅ 已开启${NC}" || echo -e "  屏幕共享:      ${YELLOW}⚠️  未确认${NC}"

        # 电源
        local sleep_val
        sleep_val=$(pmset -g 2>/dev/null | grep " sleep" | awk '{print $2}' | head -1)
        [[ "$sleep_val" == "0" ]] && echo -e "  永不睡眠:      ${GREEN}✅${NC}" || echo -e "  永不睡眠:      ${RED}✗ (当前: ${sleep_val})${NC}"
    fi

    # Tailscale
    if command -v tailscale &>/dev/null; then
        local ts_ip
        ts_ip=$(tailscale ip -4 2>/dev/null)
        [[ -n "$ts_ip" ]] && echo -e "  Tailscale:     ${GREEN}✅ $ts_ip${NC}" || echo -e "  Tailscale:     ${YELLOW}⚠️  未登录${NC}"
    fi

    # Cron
    crontab -l 2>/dev/null | grep -q "agents-healthcheck" && \
        echo -e "  健康检查:      ${GREEN}✅ cron 已设置${NC}" || echo -e "  健康检查:      ${RED}✗ 未设置${NC}"

    echo ""
    echo -e "  📁 安装目录: ${CYAN}${AGENTS_HOME}${NC}"
    echo -e "  📁 日志目录: ${CYAN}${AGENTS_LOG_DIR}${NC}"
    echo -e "  📁 配置目录: ${CYAN}${AGENTS_CONFIG_DIR}${NC}"
    echo ""
}

# ==================== 列出代理 ====================
list_agents() {
    echo -e "${BOLD}  支持的 AI 编码代理${NC}\n"
    printf "  %-15s %-40s %s\n" "ID" "描述" "安装命令"
    echo "  ─────────────────────────────────────────────────────────────"
    for agent in "${ALL_AGENTS[@]}"; do
        printf "  %-15s %-40s %s\n" "$agent" "${AGENT_DESC[$agent]:-}" "${AGENT_INSTALL_CMD[$agent]:-}"
    done
    echo ""
}

# ==================== 主函数 ====================
main() {
    parse_args "$@"

    if $DO_LIST; then
        list_agents
        exit 0
    fi

    echo ""
    echo -e "${BOLD}🤖 AI Coding Agents 无头管理器 v${VERSION}${NC}"
    echo ""

    phase_check_env

    if [[ ${#INSTALL_AGENTS[@]} -gt 0 ]]; then
        phase_install_agents
    fi

    $DO_HEADLESS && phase_headless
    $DO_DAEMON && phase_daemon
    $DO_HEALTHCHECK && phase_healthcheck
    $DO_TAILSCALE && phase_tailscale

    phase_report
}

main "$@"
