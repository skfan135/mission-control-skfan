#!/bin/bash
# 创建ASCII艺术图表并保存为文本图片

set -e

# 颜色
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'
NC='\033[0m'

# 获取数据
get_data() {
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    MEMORY_TOTAL=$(free -m | awk 'NR==2{print $2}')
    MEMORY_USED=$(free -m | awk 'NR==2{print $3}')
    MEMORY_PERC=$((MEMORY_USED * 100 / MEMORY_TOTAL))
    
    DISK_RAW=$(df -h / | awk 'NR==2 {print $3 $5}')
    DISK_USED=$(echo $DISK_RAW | sed 's/[0-9.]*G//g')
    DISK_PERC=$(echo $DISK_RAW | sed 's/.*[A-Z]//g' | tr -d '%')
}

# 绘制圆环图（简化的ASCII版本）
draw_gauge() {
    local value=$1
    local label=$2
    local color=$3
    
    printf "${color}${label}${NC}\n"
    printf "       ╔════════════════╗\n"
    printf "    ╔──╫──────────────────╫──╗\n"
    printf " ╔──╫──╫                  ╫──╫──╗\n"
    printf " ╫  ║  ║                  ║  ║  ╫\n"
    printf " ╫  ║  ║                  ║  ║  ╫\n"
    
    # 简单的进度条代替圆环
    local blocks=$((value / 10))
    local empty_blocks=$((10 - blocks))
    printf ${color}
    printf " ╫  ║  ║ "
    printf "█%.0s" $(seq 1 $blocks)
    printf "░%.0s" $(seq 1 $empty_blocks)
    printf " ║  ║  ╫\n"
    printf -e ${NC}
    
    printf " ╫  ║  ║     %3d%%      ║  ║  ╫\n" $value
    printf " ╫  ║  ║                  ║  ║  ╫\n"
    printf " ╫  ║  ║                  ║  ║  ╫\n"
    printf " ╚──╫──╫──────────────────╫──╫──╝\n"
    printf "    ╚──╫──────────────────╫──╝\n"
    printf "       ╚════════════════╝\n"
}

# 绘制条形图
draw_bar_chart() {
    local title="$1"
    shift
    local values=("$@")
    
    printf "${CYAN}${title}${NC}\n\n"
    
    for item in "${values[@]}"; do
        IFS='|' read -r name value max_value color <<< "$item"
        
        # 计算条形长度
        local bar_length=$((value * 40 / max_value))
        
        printf " %-20s ${!color}[" $name
        printf "█%.0s" $(seq 1 $bar_length)
        printf "%.*s" $((40 - bar_length)) | tr ' ' '░'
        printf "]${NC} %3d%%\n" $value
    done
}

# 主函数
main() {
    get_data
    
    # 创建输出文件
    OUTPUT="/root/.openclaw/workspace/resource-chart-$(date +%Y%m%d-%H%M%S).txt"
    
    # 生成图表
    {
        # 标题
        printf "${BLUE}"
        cat << 'EOF'
     ____        __  __     __  __     ______     ______     ______
    /\  _`\     /\ \/\ \   /\ \/\ \   /\  ___\   /\  == \   /\  ___\
    \ \ \L\ \   \ \ \_\ \  \ \ \_\ \  \ \ \__ \  \ \  __<   \ \  __\
     \ \ ,  /    \ \_____\  \ \_____\  \ \_____\  \ \_____\  \ \_____\
      \ \ \/      \/_____/   \/_____/   \/_____/   \/_____/   \/_____/
       \ \_\                                                    
        \/_/                                                    
EOF
        printf -e ${NC}
        
        printf "${YELLOW}    🖥️  服务器资源监控 - $(date '+%Y-%m-%d %H:%M:%S')${NC}\n\n"
        
        # 三个圆环图（简化版）
        printf "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"
        
        # CPU
        draw_gauge ${CPU%.*} "🖥️  CPU" $RED
        printf "\n"
        
        # 内存
        draw_gauge $MEMORY_PERC "🧠 内存" $GREEN
        printf "\n"
        
        # 磁盘
        draw_gauge $DISK_PERC "💾 磁盘" $YELLOW
        printf "\n"
        
        # 进程条形图
        printf "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"
        
        # 获取进程数据
        MAPS=()
        while IFS= read -r line; do
            if [[ $line =~ (.+)\ ([0-9.]+)% ]]; then
                name="${BASH_REMATCH[1]}"
                perc="${BASH_REMATCH[2]%.*}"
                # 限制名长度
                name=$(echo "$name" | cut -c1-20)
                MAPS+=("$name|$perc|100|${RED}")
            fi
        done <<< "$(ps aux --sort=-%mem | head -6 | awk 'NR>1{print $11 " " $4}')"
        
        draw_bar_chart "🔥 Top 进程内存使用" "${MAPS[@]}"
        
        # 系统信息
        printf "\n${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"
        printf "${CYAN}ℹ️  系统信息${NC}\n"
        printf "   ───────────────────────\n"
        printf "   运行时间: $(uptime -p | sed 's/up //')\n"
        printf "   负载平均: $(uptime | awk -F'load average:' '{print $2}')\n"
        printf "   当前用户: $(who | wc -l) 人在线\n"
        printf "   进程总数: $(ps aux | wc -l) 个\n"
        
    } | tee "$OUTPUT"
    
    echo ""
    echo -e "${GREEN}✅ ASCII图表已保存到: $OUTPUT${NC}"
    echo ""
    echo -e "${BLUE}💡 提示: 使用以下命令查看:${NC}"
    echo "   cat $OUTPUT"
    echo "   or"
    echo "   less -R $OUTPUT  (支持颜色)"
}

# 执行
main "$@"