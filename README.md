# Mission Control 🎛️

AI 任务管理看板系统

## 快速开始

1. 访问 [GitHub Pages](https://skfan135.github.io/mission-control-skfan/)
2. 查看和拖拽任务卡片
3. 任务状态会自动同步

## 任务状态

- **Permanent** - 永久性任务（如每日检查）
- **Backlog** - 待办任务
- **In Progress** - 🤖 AI 正在执行
- **Review** - 等待审核
- **Done** - 已完成

## 自动化

当任务移至 "In Progress" 时，AI 助手会：
1. 自动接收任务
2. 执行子任务
3. 更新进度
4. 完成后移至 "Review"

## 本地运行

```bash
# 启动本地服务器
python3 -m http.server 8080

# 访问
http://localhost:8080
```

## 更新任务

```bash
# 使用 mc-update.sh 脚本
./scripts/mc-update.sh status <task_id> done
./scripts/mc-update.sh comment <task_id> "进度更新"
./scripts/mc-update.sh complete <task_id> "完成总结"
```

---

*由 Mission Control 和 AI 助手共同管理*