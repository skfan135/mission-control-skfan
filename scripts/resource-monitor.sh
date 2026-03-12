#!/bin/bash
# 简单的资源监控图表生成（使用ASCII艺术）

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 获取资源使用情况
get_resources() {
    # CPU
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    
    # 内存
    MEMORY_INFO=$(free -m | awk 'NR==2{printf "%.0f %.0f %.0f", $3/$3*100/$2*100, $3, $2}')
    MEMORY_USAGE=$(echo $MEMORY_INFO | awk '{print $1}')
    MEMORY_USED=$(echo $MEMORY_INFO | awk '{print $2}')
    MEMORY_TOTAL=$(echo $MEMORY_INFO | awk '{print $3}')
    
    # 磁盘
    DISK_INFO=$(df / | awk 'NR==2 {printf "%.0f %.0f %.0f", $3/$2*100, $3/1024/1024, $2/1024/1024}')
    DISK_USAGE=$(echo $DISK_INFO | awk '{print $1}')
    DISK_USED=$(echo $DISK_INFO | awk '{print $1}')  # 修正，使用正确的字段
    DISK_TOTAL=$(echo $DISK_INFO | awk '{print $3}')
    
    # 获取磁盘使用（修正版）
    DISK_RAW=$(df -h / | awk 'NR==2 {print $3, $2, $5}' | tr -d '%')
    DISK_USED_GB=$(echo $DISK_RAW | awk '{print $1}')
    DISK_TOTAL_GB=$(echo $DISK_RAW | awk '{print $2}')
    DISK_USAGE=$(echo $DISK_RAW | awk '{print $3}')
    
    # 获取前5个进程
    TOP_PROCS=$(ps aux --sort=-%mem | head -6 | awk 'NR>1 {printf "%-12s %5.1f%%\n", $11, $4}' | head -5)
}

# 生成ASCII图表
draw_bar() {
    local value=$1
    local max_value=$2
    local width=50
    local value_int=$(echo "$value" | cut -d. -f1)
    local filled=$((value_int * width / max_value))
    
    printf "["
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $((width - filled)) | tr ' ' '░'
    printf "] %3.0f%%\n" $value
}

# 生成报告
generate_report() {
    get_resources
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📊 服务器资源监控报告$(date '+ %Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # CPU
    echo -e "${YELLOW}🖥️  CPU 使用率${NC}"
    draw_bar $CPU_USAGE 100
    echo ""
    
    # 内存
    echo -e "${YELLOW}🧠 内存使用率${NC}"
    printf "已使用: ${RED}%dMB${NC} / 总计: ${GREEN}%dMB${NC}, 使用率: " $MEMORY_USED $MEMORY_TOTAL
    draw_bar $MEMORY_USAGE 100
    echo ""
    
    # 磁盘
    echo -e "${YELLOW}💾 磁盘使用率${NC}"
    printf "已使用: ${RED}%s${NC} / 总计: ${GREEN}%s${NC}, 使用率: " $DISK_USED_GB $DISK_TOTAL_GB
    draw_bar $DISK_USAGE 100
    echo ""
    
    # Top进程
    echo -e "${YELLOW}🔥 Top 5 内存占用进程${NC}"
    echo "$TOP_PROCS" | while IFS= read -r line; do
        echo "  $line"
    done
    echo ""
    
    # 系统信息
    echo -e "${YELLOW}ℹ️  系统信息${NC}"
    echo "  运行时间: $(uptime -p | cut -d' ' -f2-)"
    echo "  负载平均: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 主函数
main() {
    # 生成文本报告
    REPORT_FILE="/root/.openclaw/workspace/resource-report-$(date +%Y%m%d-%H%M%S).txt"
    generate_report | tee "$REPORT_FILE"
    
    echo ""
    echo -e "${GREEN}✅ 报告已保存到: $REPORT_FILE${NC}"
    echo ""
    echo -e "${BLUE}📝 要生成PNG图表版，请运行：${NC}"
    echo "  pip install matplotlib psutil --break-system-packages"
    echo "  python3 /root/.openclaw/workspace/scripts/generate-resource-chart.py"
}

# 执行
main "$@"