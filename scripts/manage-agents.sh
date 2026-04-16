#!/bin/bash
# ============================================================
#  AI Coding Agents 多代理管理脚本
#  用法: manage-agents.sh <command> [agent]
# ============================================================
set -uo pipefail

AGENTS_HOME="${AGENTS_HOME:-$HOME/.coding-agents}"
AGENTS_LOG_DIR="${AGENTS_LOG_DIR:-$HOME/.coding-agents/logs}"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# 代理二进制名映射
declare -A AGENT_BIN_MAP=(
    [opencode]="opencode"
    [claude-code]="claude"
    [codex-cli]="codex"
    [gemini-cli]="gemini"
    [aider]="aider"
    [kilo-code]="kilo-code"
    [copilot-cli]="gh"
)

declare -A AGENT_DISPLAY_NAME=(
    [opencode]="OpenCode"
    [claude-code]="Claude Code"
    [codex-cli]="Codex CLI"
    [gemini-cli]="Gemini CLI"
    [aider]="Aider"
    [kilo-code]="Kilo Code"
    [copilot-cli]="Copilot CLI"
    [cursor]="Cursor"
    [windsurf]="Windsurf"
)

# ==================== 命令实现 ====================

cmd_status() {
    echo -e "\n${BOLD}📊 AI Coding Agents 状态${NC}\n"
    printf "  %-15s %-12s %-10s %-10s %s\n" "代理" "状态" "PID" "内存" "版本"
    echo "  ──────────────────────────────────────────────────────"

    local found=0
    for id in "${!AGENT_BIN_MAP[@]}"; do
        local bin="${AGENT_BIN_MAP[$id]}"
        local display="${AGENT_DISPLAY_NAME[$id]:-$id}"

        if command -v "$bin" &>/dev/null; then
            local version
            version=$("$bin" --version 2>/dev/null | head -1 | tr -d '\n')
            local pid=""
            local mem=""
            if pgrep -f "$bin" >/dev/null 2>&1; then
                pid=$(pgrep -f "$bin" | head -1)
                mem=$(ps -o rss= -p "$pid" 2>/dev/null | awk '{printf "%.0fMB", $1/1024}')
                printf "  ${GREEN}%-15s${NC} %-12s %-10s %-10s %s\n" "$display" "运行中" "$pid" "$mem" "$version"
            else
                printf "  ${YELLOW}%-15s${NC} %-12s %-10s %-10s %s\n" "$display" "已安装" "-" "-" "$version"
            fi
            found=$((found + 1))
        fi
    done

    # GUI 应用
    for id in cursor windsurf; do
        local app_name="${AGENT_DISPLAY_NAME[$id]}"
        local app_path="/Applications/${app_name}.app"
        if [[ -d "$app_path" ]]; then
            if pgrep -f "$app_name" >/dev/null 2>&1; then
                local pid=$(pgrep -f "$app_name" | head -1)
                printf "  ${GREEN}%-15s${NC} %-12s %-10s %-10s %s\n" "$app_name" "运行中" "$pid" "-" "GUI"
            else
                printf "  ${YELLOW}%-15s${NC} %-12s %-10s %-10s %s\n" "$app_name" "已安装" "-" "-" "GUI"
            fi
            found=$((found + 1))
        fi
    done

    [[ $found -eq 0 ]] && echo -e "  ${RED}未检测到已安装的 AI 编码代理${NC}"
    echo ""
}

cmd_list() {
    echo -e "\n${BOLD}📋 已安装的代理${NC}\n"
    for id in "${!AGENT_BIN_MAP[@]}"; do
        local bin="${AGENT_BIN_MAP[$id]}"
        if command -v "$bin" &>/dev/null; then
            echo -e "  ${GREEN}✅${NC} ${AGENT_DISPLAY_NAME[$id]:-$id} ($(which "$bin"))"
        fi
    done
    echo ""
}

cmd_start() {
    local agent="$1"
    local bin="${AGENT_BIN_MAP[$agent]:-$agent}"
    [[ -z "$bin" ]] && { echo "用法: $0 start <agent>"; exit 1; }
    command -v "$bin" &>/dev/null || { echo "错误: $bin 未安装"; exit 1; }

    if [[ "$(uname)" == "Darwin" ]]; then
        local plist="$LAUNCH_AGENT_DIR/com.codingagent.${agent}.plist"
        if [[ -f "$plist" ]]; then
            launchctl load -w "$plist" 2>/dev/null && echo "✅ $agent 已启动 (LaunchAgent)" || echo "❌ 启动失败"
        else
            echo "⚠️  未找到 $agent 的 LaunchAgent，请先运行安装脚本 --daemon"
        fi
    else
        sudo systemctl start "codingagent-${agent}" 2>/dev/null && echo "✅ $agent 已启动" || echo "❌ 启动失败"
    fi
}

cmd_stop() {
    local agent="$1"
    local bin="${AGENT_BIN_MAP[$agent]:-$agent}"

    if [[ "$(uname)" == "Darwin" ]]; then
        local plist="$LAUNCH_AGENT_DIR/com.codingagent.${agent}.plist"
        [[ -f "$plist" ]] && launchctl unload "$plist" 2>/dev/null
    else
        sudo systemctl stop "codingagent-${agent}" 2>/dev/null
    fi

    # 确保进程停止
    pkill -f "$bin" 2>/dev/null
    echo "✅ $agent 已停止"
}

cmd_restart() {
    cmd_stop "$1"
    sleep 2
    cmd_start "$1"
}

cmd_logs() {
    local agent="$1"
    local log_dir="$AGENTS_LOG_DIR"

    if [[ -z "$agent" ]]; then
        echo "最近日志:"
        ls -lt "$log_dir"/*.log 2>/dev/null | head -10
    else
        echo "=== $agent stdout ==="
        tail -30 "$log_dir/${agent}-stdout.log" 2>/dev/null || echo "(无日志)"
        echo ""
        echo "=== $agent stderr ==="
        tail -30 "$log_dir/${agent}-stderr.log" 2>/dev/null || echo "(无日志)"
    fi
}

cmd_help() {
    echo "AI Coding Agents 管理器"
    echo ""
    echo "用法: $0 <command> [agent]"
    echo ""
    echo "命令:"
    echo "  status              查看所有代理状态"
    echo "  list                列出已安装的代理"
    echo "  start <agent>       启动代理"
    echo "  stop <agent>        停止代理"
    echo "  restart <agent>     重启代理"
    echo "  logs [agent]        查看日志"
    echo "  help                显示帮助"
    echo ""
    echo "代理 ID: ${!AGENT_BIN_MAP[*]} cursor windsurf"
}

# ==================== 主入口 ====================
case "${1:-}" in
    status)  cmd_status ;;
    list)    cmd_list ;;
    start)   cmd_start "${2:-}" ;;
    stop)    cmd_stop "${2:-}" ;;
    restart) cmd_restart "${2:-}" ;;
    logs)    cmd_logs "${2:-}" ;;
    help|-h|"") cmd_help ;;
    *)       echo "未知命令: $1"; cmd_help; exit 1 ;;
esac
