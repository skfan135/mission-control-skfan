#!/bin/bash
# Mission Control 监控脚本
# 监控任务状态变化并自动执行

set -e

LOG_FILE="$HOME/.openclaw/workspace/logs/mission-monitor.log"
TASKS_FILE="$HOME/.openclaw/workspace/data/tasks.json"
AI_HANDLER="$HOME/.openclaw/workspace/scripts/ai-task-handler.sh"

# 创建日志目录
mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 获取任务状态
get_task_status() {
    local task_id="$1"
    jq -r ".tasks[] | select(.id == \"$task_id\") | .status" "$TASKS_FILE"
}

# 检查任务变化
check_task_changes() {
    # 查找刚变为 "in_progress" 的任务
    local in_progress_tasks=$(jq -r '.tasks[] | select(.status == "in_progress" and (.processingStartedAt // empty) | fromdateiso8601 > now - 60)' "$TASKS_FILE")
    
    if [ -n "$in_progress_tasks" ]; then
        echo "$in_progress_tasks" | jq -r '. | "\(.id)\"\t\"\(.title)\"\t\"\(.description // "")\"' | while IFS=$'\t' read -r task_id title desc; do
            log "检测到新任务开始: $title"
            
            # 调用 AI 处理器
            if "$AI_HANDLER" "$task_id" "$title" "$desc"; then
                log "✓ 任务处理成功: $task_id"
            else
                log "✗ 任务处理失败: $task_id"
            fi
        done
    fi
}

# 清理旧日志
cleanup_logs() {
    # 保留最近 7 天的日志
    find "$(dirname "$LOG_FILE")" -name "*.log" -mtime +7 -delete 2>/dev/null || true
}

# 主函数
main() {
    log "Mission Control 监控启动"
    
    # 检查文件存在
    if [ ! -f "$TASKS_FILE" ]; then
        log "❌ 任务文件不存在: $TASKS_FILE"
        exit 1
    fi
    
    # 检查任务变化
    check_task_changes
    
    # 清理日志
    cleanup_logs
    
    log "监控检查完成"
}

# 如果脚本被直接调用
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi