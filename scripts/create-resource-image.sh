#!/bin/bash
# 创建资源监控图片（使用HTML/CSS渲染）

set -e

# 生成HTML报告
generate_html() {
    # 获取数据
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    MEMORY_TOTAL=$(free -m | awk 'NR==2{print $2}')
    MEMORY_USED=$(free -m | awk 'NR==2{print $3}')
    MEMORY_PERC=$((MEMORY_USED * 100 / MEMORY_TOTAL))
    
    DISK_RAW=$(df -h / | awk 'NR==2 {print $3 " " $5}')
    DISK_USED=$(echo $DISK_RAW | awk '{print $1}')
    DISK_PERC=$(echo $DISK_RAW | awk '{print $2}' | tr -d '%')
    
    OUTPUT="/root/.openclaw/workspace/resource-monitor.html"
    
    cat > "$OUTPUT" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>服务器资源监控</title>
    <style>
        body {
            font-family: 'Consolas', 'Monaco', monospace;
            background: #1e1e1e;
            color: #fff;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            text-align: center;
            font-size: 24px;
            margin-bottom: 30px;
            color: #61dafb;
            text-shadow: 0 0 10px #61dafb80;
        }
        
        .grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .card {
            background: #2d2d30;
            border: 1px solid #3e3e42;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 0 20px rgba(0,0,0,0.3);
        }
        
        .gauge {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 200px;
        }
        
        .gauge-container {
            position: relative;
            width: 150px;
            height: 150px;
        }
        
        .gauge-circle {
            width: 100%;
            height: 100%;
            border-radius: 50%;
            background: conic-gradient(
                #ff4757 0deg,
                #5352ed $$CPUdeg,
                #2d3436 $$CPUdeg
            );
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
        }
        
        .gauge-circle::before {
            content: '';
            position: absolute;
            width: 100px;
            height: 100px;
            background: #2d2d30;
            border-radius: 50%;
        }
        
        .gauge-value {
            position: absolute;
            font-size: 24px;
            font-weight: bold;
            color: #fff;
        }
        
        .gauge-label {
            text-align: center;
            font-size: 16px;
            margin-top: 10px;
        }
        
        .bar-chart {
            height: 250px;
            display: flex;
            align-items: flex-end;
            justify-content: space-around;
            padding: 20px;
        }
        
        .bar {
            width: 60px;
            background: linear-gradient(to top, #5f27cd, #00d2d3);
            border-radius: 4px 4px 0 0;
            position: relative;
            transition: all 0.3s;
        }
        
        .bar:hover {
            transform: scaleY(1.05);
            background: linear-gradient(to top, #ff6348, #feca57);
        }
        
        .bar-label {
            position: absolute;
            bottom: -30px;
            left: 50%;
            transform: translateX(-50%);
            font-size: 12px;
            white-space: nowrap;
        }
        
        .bar-value {
            position: absolute;
            top: -25px;
            left: 50%;
            transform: translateX(-50%);
            font-size: 14px;
            font-weight: bold;
        }
        
        .process-list {
            list-style: none;
            padding: 0;
        }
        
        .process-item {
            display: flex;
            justify-content: space-between;
            padding: 10px;
            margin: 5px 0;
            background: #3c3c3c;
            border-radius: 4px;
            transition: all 0.2s;
        }
        
        .process-item:hover {
            background: #4a4a4a;
            transform: translateX(5px);
        }
        
        .stats {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 15px;
        }
        
        .stat-item {
            text-align: center;
            padding: 15px;
            background: #3c3c3c;
            border-radius: 8px;
        }
        
        .stat-value {
            font-size: 24px;
            color: #61dafb;
        }
        
        .stat-label {
            font-size: 12px;
            opacity: 0.8;
        }
        
        .timestamp {
            text-align: center;
            opacity: 0.7;
            font-size: 14px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <h1 class="header">🖥️ 服务器资源监控</h1>
    
    <div class="grid">
        <!-- CPU Gauge -->
        <div class="card">
            <div class="gauge">
                <div>
                    <div class="gauge-container">
                        <div class="gauge-circle" style="background: conic-gradient(#ff4757 0deg, #ff4757 ${CPU}deg, #2d3436 ${CPU}deg)">
                            <div class="gauge-value">${CPU}%</div>
                        </div>
                    </div>
                    <div class="gauge-label">CPU 使用率</div>
                </div>
            </div>
        </div>
        
        <!-- Memory Gauge -->
        <div class="card">
            <div class="gauge">
                <div>
                    <div class="gauge-container">
                        <div class="gauge-circle" style="background: conic-gradient(#26de81 0deg, #26de81 ${MEMORY_PERC}deg, #2d3436 ${MEMORY_PERC}deg)">
                            <div class="gauge-value">${MEMORY_PERC}%</div>
                        </div>
                    </div>
                    <div class="gauge-label">内存使用率</div>
                    <div>
                        <div style="text-align: center; margin-top: 10px;">
                            <span style="color: #26de81;">${MEMORY_USED}MB</span> / 
                            <span style="color: #fff;">${MEMORY_TOTAL}MB</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Disk Gauge -->
        <div class="card">
            <div class="gauge">
                <div>
                    <div class="gauge-container">
                        <div class="gauge-circle" style="background: conic-gradient(#fd9644 0deg, #fd9644 ${DISK_PERC}deg, #2d3436 ${DISK_PERC}deg)">
                            <div class="gauge-value">${DISK_PERC}%</div>
                        </div>
                    </div>
                    <div class="gauge-label">磁盘使用率</div>
                    <div>
                        <div style="text-align: center; margin-top: 10px;">
                            <span style="color: #fd9644;">${DISK_USED}</span> / 
                            <span style="color: #fff;">50G</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Top Processes -->
        <div class="card">
            <h3 style="text-align: center; margin-bottom: 20px;">🔥 Top 5 进程</h3>
            <ul class="process-list">
EOF
    
    # 添加进程信息
    ps aux --sort=-%mem | head -6 | awk 'NR>1 {print $11, $4}' | while read name mem; do
        name=$(basename "$name")
        if [ ${#name} -gt 15 ]; then
            name="${name:0:15}..."
        fi
        cat >> "$OUTPUT" << EOFP
                <li class="process-item">
                    <span>$name</span>
                    <span>${mem}%</span>
                </li>
EOFP
    done
    
    cat >> "$OUTPUT" << EOF
            </ul>
        </div>
    </div>
    
    <!-- System Stats -->
    <div class="card">
        <div class="stats">
            <div class="stat-item">
                <div class="stat-value">$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')</div>
                <div class="stat-label">负载 1分钟</div>
            </div>
            <div class="stat-item">
                <div class="stat-value">$(ps aux | wc -l)</div>
                <div class="stat-label">总进程数</div>
            </div>
            <div class="stat-item">
                <div class="stat-value">$(who | wc -l)</div>
                <div class="stat-label">在线用户</div>
            </div>
            <div class="stat-item">
                <div class="stat-value">$(uptime -p | cut -d' ' -f2-)</div>
                <div class="stat-label">运行时间</div>
            </div>
        </div>
    </div>
    
    <div class="timestamp">
        监控时间: $(date '+%Y-%m-%d %H:%M:%S')
    </div>
</body>
</html>
EOF
    
    echo ""
    echo -e "\033[32m✅ HTML报告已生成: $OUTPUT\033[0m"
    echo ""
    echo -e "\033[34m💡 提示: 可以使用浏览器打开查看，或使用 puppeteer 等工具截图\033[0m"
}

# 主函数
main() {
    generate_html
    
    # 如果有puppeteer，尝试截图
    if command -v puppeteer &> /dev/null; then
        echo ""
        echo "正在生成截图..."
        puppeteer screenshot "$OUTPUT" -o "/root/.openclaw/workspace/resource-monitor-$(date +%Y%m%d-%H%M%S).png"
    fi
}

# 执行
main "$@"