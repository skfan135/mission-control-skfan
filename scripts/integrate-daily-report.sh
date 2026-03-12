#!/bin/bash
# 集成日报系统的脚本

set -e

echo "📊 集成 Mission Control 与日报系统"
echo "=================================="

# 配置路径
MC_FILE=$HOME/.openclaw/workspace/data/tasks.json
REPORT_SCRIPT=$HOME/.openclaw/workspace/scripts/generate-mc-stats.sh

# 创建统计脚本
echo ""
echo "📝 1. 创建任务统计脚本..."

cat > $REPORT_SCRIPT << 'EOF'
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

STATS=$(jq -c '{
    date: (now | strftime("%Y-%m-%d")),
    total: (.tasks | length),
    by_status: (
        .tasks 
        | group_by(.status) 
        | map({status: .[0].status, count: length}) 
        | from_entries
    ),
    by_priority: (
        .tasks 
        | group_by(.priority) 
        | map({priority: .[0].priority, count: length}) 
        | from_entries
    ),
    completed_today: [
        .tasks[] 
        | select(.completedAt and (.completedAt | split("T")[0] == (now | strftime("%Y-%m-%d"))))
    ] | length,
    tasks_in_progress: [
        .tasks[] 
        | select(.status == "in_progress")
    ] | length,
    recent_activity: [
        .tasks[] 
        | select(.processingStartedAt) 
        | {title, started: .processingStartedAt, status}
    ][0:5]
}' "$TASKS_FILE")

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
EOF

chmod +x $REPORT_SCRIPT

echo "✅ 统计脚本已创建"

# 更新 HEARTBEAT.md
echo ""
echo "📝 2. 更新 HEARTBEAT.md..."

HEARTBEAT_FILE=$HOME/.openclaw/workspace/HEARTBEAT.md

# 添加任务检查到 heartbeat
if ! grep -q "任务检查" "$HEARTBEAT_FILE"; then
    cat >> "$HEARTBEAT_FILE" << 'EOF'

## 📊 任务检查（每天 9:00 和 18:00）

1. 生成任务统计报告
2. 检查进行中的任务是否有进度
3. 识别超时任务（超过24小时在"进行中"）
4. 将统计加入日报
EOF
fi

echo "✅ HEARTBEAT.md 已更新"

# 创建 cron 配置
echo ""
echo "📝 3. 创建定时任务..."

CRON_ENTRY="0 9,18 * * * $REPORT_SCRIPT"

# 检查是否已存在
if ! crontab -l 2>/dev/null | grep -q "$REPORT_SCRIPT"; then
    (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
    echo "✅ 定时任务已添加：每天 9:00 和 18:00 生成统计"
else
    echo "⚠️  定时任务已存在"
fi

# 显示当前 crontab
echo ""
echo "📅 当前的定时任务："
crontab -l | grep -E "(daily-report|mc-stats)" || echo "无相关任务"

# 测试统计脚本
echo ""
echo "🧪 4. 测试统计脚本..."
if $REPORT_SCRIPT; then
    echo "✅ 测试成功"
else
    echo "❌ 测试失败"
fi

# 集成到 daily-report-joig
echo ""
echo "📝 5. 检查日报系统集成..."

REPORT_SKILL="$HOME/.openclaw/workspace/skills/daily-report-joig/SKILL.md"
if [ -f "$REPORT_SKILL" ] && ! grep -q "mc-stats" "$REPORT_SKILL"; then
    echo "⚠️  需要手动集成到日报系统"
    echo "📝 请在 daily-report-joig 中添加 mc-stats.json 数据源"
else
    echo "✅ 日报系统已配置"
fi

echo ""
echo "🎉 集成完成！"
echo ""
echo "💡 使用说明："
echo "   1. 手动生成统计: $REPORT_SCRIPT"
echo "   2. 查看统计文件: $REPORT_FILE"
echo "   3. 定时任务每日 9:00 和 18:00 自动执行"
echo ""
echo "🔗 相关文件："
echo "   - 任务数据: $TASKS_FILE"
echo "   - 统计脚本: $REPORT_SCRIPT"
echo "   - 统计结果: $REPORT_FILE"