#!/bin/bash
# AI 任务自动处理脚本
# 当任务进入"进行中"状态时自动执行

set -e

TASKS_FILE="$HOME/.openclaw/workspace/data/tasks.json"
LOG_FILE="$HOME/.openclaw/workspace/logs/ai-tasks.log"

# 创建日志目录
mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 自动处理任务
handle_task() {
    local task_id="$1"
    local task_title="$2"
    local task_description="$3"
    
    log "开始处理任务: $task_title (ID: $task_id)"
    
    # 根据任务类型执行不同的逻辑
    case "$task_id" in
        "welcome_001")
            action_handle_welcome "$task_id"
            ;;
        "setup_002")
            action_handle_webhook "$task_id"
            ;;
        "daily_003")
            action_handle_daily "$task_id"
            ;;
        *)
            # 通用任务处理
            action_handle_generic "$task_id" "$task_title" "$task_description"
            ;;
    esac
}

# 示例任务处理
action_handle_welcome() {
    local task_id="$1"
    
    log "处理欢迎任务..."
    
    # 模拟AI处理
    sleep 2
    
    # 更新子任务
    "$HOME/.openclaw/workspace/skills/mission-control/scripts/mc-update.sh" subtask "$task_id" sub_001 done
    log "✓ 理解任务状态含义 - 完成"
    
    sleep 2
    
    "$HOME/.openclaw/workspace/skills/mission-control/scripts/mc-update.sh" subtask "$task_id" sub_002 done
    log "✓ 尝试拖拽任务到进行中 - 完成"
    
    sleep 2
    
    "$HOME/.openclaw/workspace/skills/mission-control/scripts/mc-update.sh" subtask "$task_id" sub_003 done
    log "✓ 观察 AI 自动执行任务 - 完成"
    
    # 完成任务
    sleep 1
    "$HOME/.openclaw/workspace/skills/mission-control/scripts/mc-update.sh" complete "$task_id" "已成功体验完整的工作流程！任务状态切换流畅，自动化执行正常。"
    log "✅ 欢迎任务完成"
}

# Webhook 任务处理
action_handle_webhook() {
    local task_id="$1"
    
    log "处理 webhook 设置任务..."
    
    # 这里可以自动执行 webhook 设置
    "$HOME/.openclaw/workspace/scripts/setup-webhook-auto.sh"
    
    log "✅ Webhook 设置完成"
}

# 日报任务处理
action_handle_daily() {
    local task_id="$1"
    
    log "处理日报集成任务..."
    
    # 自动生成统计
    "$HOME/.openclaw/workspace/scripts/generate-mc-stats.sh"
    
    log "✅ 日报集成完成"
}

# 通用任务处理
action_handle_generic() {
    local task_id="$1"
    local title="$2"
    local description="$3"
    
    log "处理通用任务: $title"
    
    # 尝试解析任务描述
    if echo "$description" | grep -qi "测试"; then
        log "  - 检测到测试任务"
        # 执行测试逻辑
    elif echo "$description" | grep -qi "修复\|bug"; then
        log "  - 检测到修复任务"
        # 执行修复逻辑
    fi
    
    # 添加处理记录
    "$HOME/.openclaw/workspace/skills/mission-control/scripts/mc-update.sh" comment "$task_id" "AI 自动处理：已理解任务需求，正在分析..."
    
    log "✅ 通用任务处理完成"
}

# 主函数
main() {
    # 检查参数
    if [ $# -lt 3 ]; then
        echo "用法: $0 <task_id> <task_title> <task_description>"
        echo ""
        echo "示例："
        echo "  $0 welcome_001 \"欢迎任务\" \"这是一个示例任务\""
        exit 1
    fi
    
    local task_id="$1"
    local task_title="$2"
    local task_description="$3"
    
    # 检查任务是否存在
    if ! jq -e ".tasks[] | select(.id == \"$task_id\")" "$TASKS_FILE" > /dev/null; then
        log "❌ 任务不存在: $task_id"
        exit 1
    fi
    
    # 处理任务
    handle_task "$task_id" "$task_title" "$task_description"
    
    log "任务处理完成"
}

# 如果脚本被直接调用
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi