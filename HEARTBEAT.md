# HEARTBEAT.md

# Keep this file empty (or with only comments) to skip heartbeat API calls.

# Add tasks below when you want the agent to check something periodically.

---

## 📊 每日飞书日报（自动任务）

**触发条件：** 每天 0 点 (cron: daily-feishu-report)

**执行流程：**
1. 回顾过去 24 小时的对话历史
2. 自动提取 highlights（完成的任务、学到的东西、重要决定）
3. 识别 blockers（遇到的问题、待解决的事项）
4. 生成 next（明天的计划、待办事项）
5. 调用 `daily-report-joig` 生成日报 Markdown
6. 调用 `feishu_doc` (action: create) 创建飞书文档
7. 文档标题：`日报 (YYYY-MM-DD)`
8. 文档创建后，在飞书发送通知给老板

**配置：**
- Cron 任务名：daily-feishu-report
- 时区：Asia/Shanghai
- 交付渠道：feishu
