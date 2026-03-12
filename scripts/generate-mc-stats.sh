#!/bin/bash
# Mission Control 任务统计脚本

set -e

TASKS_FILE="$HOME/.openclaw/workspace/data/tasks.json"
REPORT_FILE="$HOME/.openclaw/workspace/data/mc-stats.json"

# 确保文件存在
if [ ! -f "$TASKS_FILE" ]; then
    echo "❌ 任务文件不存在: $TASKS_FILE"
    exit 1
fi

# 生成统计
echo "📊 正在生成任务统计..."

# 逐项计算以避免 null 问题
TOTAL=$(jq '.tasks | length' "$TASKS_FILE")
BACKLOG=$(jq '.tasks | map(select(.status == "backlog")) | length' "$TASKS_FILE")
IN_PROGRESS=$(jq '.tasks | map(select(.status == "in_progress")) | length' "$TASKS_FILE")
REVIEW=$(jq '.tasks | map(select(.status == "review")) | length' "$TASKS_FILE")
DONE=$(jq '.tasks | map(select(.status == "done")) | length' "$TASKS_FILE")
PERMANENT=$(jq '.tasks | map(select(.status == "permanent")) | length' "$TASKS_FILE")

HIGH=$(jq '.tasks | map(select(.priority == "high")) | length' "$TASKS_FILE")
MEDIUM=$(jq '.tasks | map(select(.priority == "medium")) | length' "$TASKS_FILE")
LOW=$(jq '.tasks | map(select(.priority == "low")) | length' "$TASKS_FILE")

COMPLETED_TODAY=$(jq --arg today "$(date +%Y-%m-%d)" '[.tasks[] | select(.completedAt and (.completedAt | split("T")[0] == $today))] | length' "$TASKS_FILE")

STATS=$(jq -c --argjson total "$TOTAL" \
--argjson backlog "$BACKLOG" \
--argjson in_progress "$IN_PROGRESS" \
--argjson review "$REVIEW" \
--argjson done "$DONE" \
--argjson permanent "$PERMANENT" \
--argjson high "$HIGH" \
--argjson medium "$MEDIUM" \
--argjson low "$LOW" \
--argjson completed_today "$COMPLETED_TODAY" \
'{
    date: (now | strftime("%Y-%m-%d")),
    total: $total,
    by_status: {
        backlog: $backlog,
        in_progress: $in_progress,
        review: $review,
        done: $done,
        permanent: $permanent
    },
    by_priority: {
        high: $high,
        medium: $medium,
        low: $low
    },
    completed_today: $completed_today
}' <<< '{}')

# 保存统计
echo "$STATS" > "$REPORT_FILE"

# 显示简要信息
echo "$STATS" | jq -r '[
    "📅 日期: \(.date)",
    "📋 总任务: \(.total)",
    "⏳ 进行中: \(.by_status.in_progress // 0)",
    "🔍 待审核: \(.by_status.review // 0)",
    "✅ 已完成: \(.by_status.done // 0)",
    "📦 待办: \(.by_status.backlog // 0)",
    "🎯 今日完成: \(.completed_today)"
] | join("\n")'

echo ""
echo "💾 统计已保存到: $REPORT_FILE"
