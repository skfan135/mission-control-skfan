# Mission Control 🎛️

AI 任务管理看板系统

## 快速开始

1. 访问 [GitHub Pages](https://skfan135.github.io/mission-control-skfan/)
2. 中文版直接访问：[中文版](https://skfan135.github.io/mission-control-skfan/index-zh.html)
3. 查看和拖拽任务卡片
4. 任务状态会自动同步

## 任务状态

- **待办** - 准备开始的任务
- **进行中** - 🤖 AI 正在执行
- **待审核** - 完成但需要人工确认
- **已完成** - 任务完成并已确认

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