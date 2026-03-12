#!/bin/bash
# Git 操作切换到 SSH 模式

set -e

echo "🔧 检测到网络问题，切换到 SSH 模式..."

# 检查 SSH 密钥
if [ ! -f ~/.ssh/id_ed25519.pub ] && [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo "📝 生成 SSH 密钥..."
    ssh-keygen -t ed25519 -C "mission-control@openclaw" -f ~/.ssh/id_ed25519 -N ""
    echo ""
    echo "🔑 请将以下公钥添加到 GitHub："
    cat ~/.ssh/id_ed25519.pub
    echo ""
    echo "📍 添加地址：https://github.com/settings/keys"
    echo "按回车继续..."
    read
fi

# 测试 SSH 连接
echo "🔍 测试 SSH 连接..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✅ SSH 认证成功"
    
    # 远程 URL 切换到 SSH
    echo "🔄 切换远程到 SSH..."
    git remote set-url origin git@github.com:skfan135/mission-control-skfan.git
    
    # 执行原始命令
    echo "➡️  执行: $@"
    "$@"
else
    echo "❌ SSH 认证失败，请检查密钥是否已添加到 GitHub"
    exit 1
fi