#!/bin/bash
# 测试任务工作流的脚本

set -e

MC_SCRIPT="/root/.openclaw/workspace/skills/mission-control/scripts/mc-update.sh"
TASK_ID="welcome_001"

echo "🧪 测试 Mission Control 工作流"
echo "============================="

echo ""
echo "1️⃣ 将任务设置为进行中..."
$MC_SCRIPT start $TASK_ID

echo ""
echo "2️⃣ 添加进度评论..."
$MC_SCRIPT comment $TASK_ID "开始执行示例任务..."

echo ""
echo "3️⃣ 完成第一个子任务..."
$MC_SCRIPT subtask $TASK_ID sub_001 done

echo ""
echo "4️⃣ 等待 2 秒..."
sleep 2

echo ""
echo "5️⃣ 完成第二个子任务..."
$MC_SCRIPT subtask $TASK_ID sub_002 done

echo ""
echo "6️⃣ 添加完成总结..."
$MC_SCRIPT complete $TASK_ID "成功演示了 Mission Control 的核心功能！任务流程清晰，自动化执行顺畅。"

echo ""
echo "7️⃣ 提交更改..."
$MC_SCRIPT push "任务工作流测试完成"

echo ""
echo "✅ 测试完成！访问以下地址查看效果："
echo "   📍 GitHub: https://github.com/skfan135/mission-control-skfan"
echo "   🌐 Pages: https://skfan135.github.io/mission-control-skfan/"
echo ""
echo "💡 提示：可以再用 setup-webhook.sh 配置实时同步"