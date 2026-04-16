#!/bin/bash
# ============================================================
#  AI Coding Agents 健康检查脚本
#  由 cron 定期调用，自动检测异常并恢复
# ============================================================
set -uo pipefail

AGENTS_HOME="${AGENTS_HOME:-$HOME/.coding-agents}"
LOG_DIR="${AGENTS_LOG_DIR:-$HOME/.coding-agents/logs}"
HEALTH_LOG="$LOG_DIR/healthcheck.log"
MAX_LOG_LINES=2000
DISK_WARN_PERCENT="${DISK_WARN_PERCENT:-90}"
ALERT_EMAIL="${ALERT_EMAIL:-}"
MAX_RESTART_PER_HOUR=3
RESTART_COUNT_FILE="$LOG_DIR/.restart_count"

mkdir -p "$LOG_DIR"

# 代理列表: id|binary|display_name
AGENTS_LIST=(
    "opencode|opencode|OpenCode"
    "claude-code|claude|Claude Code"
    "codex-cli|codex|Codex CLI"
    "gemini-cli|gemini|Gemini CLI"
    "aider|aider|Aider"
    "kilo-code|kilo-code|Kilo Code"
    "copilot-cli|gh|Copilot CLI"
)

# ==================== 工具函数 ====================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$HEALTH_LOG"
    local lines
    lines=$(wc -l < "$HEALTH_LOG" 2>/dev/null || echo 0)
    if [[ "$lines" -gt $MAX_LOG_LINES ]]; then
        tail -n $((MAX_LOG_LINES / 2)) "$HEALTH_LOG" > "${HEALTH_LOG}.tmp"
        mv "${HEALTH_LOG}.tmp" "$HEALTH_LOG"
    fi
}

send_alert() {
    local msg="$1"
    log "⚠️  告警: $msg"
    osascript -e "display notification \"$msg\" with title \"AI Agents 告警\"" 2>/dev/null || true
    [[ -n "$ALERT_EMAIL" ]] && echo "$msg" | mail -s "[AI Agents] $msg" "$ALERT_EMAIL" 2>/dev/null || true
}

check_restart_rate() {
    local now=$(date +%s)
    local cutoff=$((now - 3600))
    [[ -f "$RESTART_COUNT_FILE" ]] && awk -v c="$cutoff" '$1 > c {print}' "$RESTART_COUNT_FILE" > "${RESTART_COUNT_FILE}.tmp" && mv "${RESTART_COUNT_FILE}.tmp" "$RESTART_COUNT_FILE"
    local count=$(wc -l < "$RESTART_COUNT_FILE" 2>/dev/null || echo 0)
    if [[ "$count" -ge $MAX_RESTART_PER_HOUR ]]; then
        send_alert "频繁重启（1h内 $count 次），暂停自动恢复"
        return 1
    fi
    return 0
}

record_restart() { date +%s >> "$RESTART_COUNT_FILE"; }

# ==================== 检查函数 ====================

# 检查单个代理
check_agent() {
    local id="$1" bin="$2" display="$3"
    local should_run=false

    # 检查是否有对应的 LaunchAgent / systemd
    if [[ "$(uname)" == "Darwin" ]]; then
        [[ -f "$HOME/Library/LaunchAgents/com.codingagent.${id}.plist" ]] && should_run=true
    else
        [[ -f "/etc/systemd/system/codingagent-${id}.service" ]] && should_run=true
    fi

    if ! $should_run; then
        return 0  # 没有配置守护进程，跳过
    fi

    if command -v "$bin" &>/dev/null; then
        if pgrep -f "$bin" >/dev/null 2>&1; then
            local pid=$(pgrep -f "$bin" | head -1)
            log "✅ $display: 运行中 (PID: $pid)"
        else
            log "❌ $display: 进程不存在，尝试重启..."

            if check_restart_rate; then
                if [[ "$(uname)" == "Darwin" ]]; then
                    launchctl load -w "$HOME/Library/LaunchAgents/com.codingagent.${id}.plist" 2>/dev/null
                else
                    sudo systemctl restart "codingagent-${id}" 2>/dev/null
                fi
                sleep 5
                if pgrep -f "$bin" >/dev/null 2>&1; then
                    record_restart
                    log "✅ $display: 重启成功"
                else
                    send_alert "$display 重启失败"
                fi
            fi
        fi
    else
        log "⚠️  $display: 二进制文件不存在"
    fi
}

# 检查磁盘
check_disk() {
    local usage
    usage=$(df -h "$HOME" | awk 'NR==2 {print $5}' | tr -d '%')
    if [[ "$usage" -gt $DISK_WARN_PERCENT ]]; then
        send_alert "磁盘空间不足: ${usage}%"
    else
        log "✅ 磁盘: ${usage}% 已用"
    fi
}

# 检查内存
check_memory() {
    if [[ "$(uname)" == "Darwin" ]]; then
        local pressure
        pressure=$(memory_pressure 2>/dev/null | grep "System-wide memory free percentage" | awk '{print $NF}' | tr -d '%')
        if [[ -n "$pressure" ]] && [[ "$pressure" -lt 10 ]]; then
            send_alert "内存严重不足: 仅剩 ${pressure}%"
        fi
    fi
}

# ==================== 主逻辑 ====================
main() {
    log "═══ 健康检查开始 ═══"

    for entry in "${AGENTS_LIST[@]}"; do
        IFS='|' read -r id bin display <<< "$entry"
        check_agent "$id" "$bin" "$display"
    done

    check_disk
    check_memory

    log "═══ 健康检查完成 ═══"
}

main
