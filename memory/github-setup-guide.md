# GitHub PAT 权限设置指南

## 当前 PAT 问题
错误：`Resource not accessible by personal access token (createRepository)`

## 解决方案

### 1. 创建新的 Personal Access Token
访问：https://github.com/settings/tokens

**必需权限范围 (scopes)：**
- ✅ `repo` - 完整的仓库访问权限
- ✅ `repo:status` - 访问提交状态
- ✅ `public_repo` - 访问公共仓库
- ✅ `admin:repo_hook` - 管理仓库 webhooks
- ✅ `user` - 访问用户信息

### 2. 推荐的完整权限列表
```
✅ repo (Full control of private repositories)
✅ admin:org (Read and write org and team membership)
✅ admin:public_key (Read and write public keys)
✅ admin:repo_hook (Read and write repository hooks)
✅ delete_repo (Delete repositories)
✅ gist (Create gists)
✅ notifications (Access notifications)
✅ user (Update user information)
✅ write:discussion (Read and write team discussions)
```

### 3. 替代方案：手动创建仓库
如果 PAT 权限暂时无法修改：

1. **手动创建仓库**：
   - 访问 https://github.com/new
   - 仓库名：mission-control-skfan
   - 设为 Public
   - 不添加 README（我们已有文件）

2. **推送现有代码**：
   ```bash
   git remote set-url origin https://github.com/skfan135/mission-control-skfan.git
   git push -u origin master
   ```

3. **启用 GitHub Pages**：
   - 进入仓库 Settings
   - 找到 Pages 部分
   - Source 选择 Deploy from a branch
   - Branch 选择 master
   - 保存

### 4. 验证设置
创建并配置新 PAT 后：
```bash
gh auth logout
echo "NEW_PAT" | gh auth login --with-token
gh auth status
```

## 注意事项
- PAT 显示完整权限，避免使用
- 定期轮换 PAT
- 仓库设为私有可保护任务数据