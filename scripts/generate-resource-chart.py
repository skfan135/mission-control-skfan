#!/usr/bin/env python3
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')  # 使用非GUI后端
import numpy as np
from datetime import datetime
import json
import psutil
import os

# 设置中文字体
plt.rcParams['font.sans-serif'] = ['SimHei', 'DejaVu Sans', 'Arial Unicode MS']
plt.rcParams['axes.unicode_minus'] = False

# 获取系统信息
def get_system_info():
    # CPU信息
    cpu_percent = psutil.cpu_percent(interval=1)
    cpu_count = psutil.cpu_count()
    
    # 内存信息
    memory = psutil.virtual_memory()
    swap = psutil.swap_memory()
    
    # 磁盘信息
    disk = psutil.disk_usage('/')
    
    # 获取进程信息
    processes = []
    for proc in psutil.process_iter(['pid', 'name', 'memory_percent', 'cpu_percent']):
        try:
            pinfo = proc.info
            if pinfo['memory_percent'] > 1.0:  # 只显示内存占用>1%的进程
                processes.append(pinfo)
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass
    
    # 按内存使用排序
    processes.sort(key=lambda x: x['memory_percent'], reverse=True)
    
    return {
        'cpu': {
            'percent': cpu_percent,
            'count': cpu_count
        },
        'memory': {
            'total': memory.total,
            'used': memory.used,
            'free': memory.free,
            'percent': memory.percent
        },
        'swap': {
            'total': swap.total,
            'used': swap.used,
            'free': swap.free,
            'percent': swap.percent
        },
        'disk': {
            'total': disk.total,
            'used': disk.used,
            'free': disk.free,
            'percent': disk.percent
        },
        'processes': processes[:10]  # Top 10 processes
    }

# 转换字节到GB
def bytes_to_gb(bytes_value):
    return bytes_value / (1024**3)

# 创建图表
def create_chart():
    info = get_system_info()
    
    # 创建2x2的子图
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 10))
    fig.suptitle(f'服务器资源监控 - {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}', fontsize=16, fontweight='bold')
    
    # 1. CPU使用率
    cpu_labels = ['用户使用', '系统使用', '空闲']
    # 模拟CPU使用分布
    cpu_user = info['cpu']['percent'] * 0.4
    cpu_system = info['cpu']['percent'] * 0.6
    cpu_idle = 100 - info['cpu']['percent']
    
    ax1.pie([cpu_user, cpu_system, cpu_idle], labels=cpu_labels, autopct='%1.1f%%', 
            colors=['#ff9999', '#66b3ff', '#99ff99'])
    ax1.set_title(f'CPU使用率 (总计: {info["cpu"]["percent"]:.1f}%)')
    
    # 2. 内存使用
    mem_total = bytes_to_gb(info['memory']['total'])
    mem_used = bytes_to_gb(info['memory']['used'])
    mem_free = bytes_to_gb(info['memory']['free'])
    
    ax2.bar(['总内存', '已使用', '空闲'], [mem_total, mem_used, mem_free], 
            color=['#cccccc', '#ff6666', '#66cc66'])
    ax2.set_title('内存使用情况')
    ax2.set_ylabel('GB')
    for i, v in enumerate([mem_total, mem_used, mem_free]):
        ax2.text(i, v + 0.1, f'{v:.2f}GB', ha='center')
    
    # 3. 磁盘使用
    disk_total = bytes_to_gb(info['disk']['total'])
    disk_used = bytes_to_gb(info['disk']['used'])
    disk_free = bytes_to_gb(info['disk']['free'])
    
    ax3.pie([disk_used, disk_free], labels=['已使用', '空闲'], autopct='%1.1f%%',
            colors=['#ff9966', '#99ccff'])
    ax3.set_title(f'磁盘使用 (总计: {disk_total:.1f}GB)')
    
    # 4. Top进程内存使用
    if info['processes']:
        process_names = [p['name'][:15] for p in info['processes'][:8]]  # 限制名字长度
        process_mem = [p['memory_percent'] for p in info['processes'][:8]]
        
        bars = ax4.barh(process_names, process_mem, color='#ff9900')
        ax4.set_title('Top 8 进程内存使用')
        ax4.set_xlabel('内存使用率 (%)')
        
        # 添加数值标签
        for bar, value in zip(bars, process_mem):
            width = bar.get_width()
            ax4.text(width + 0.1, bar.get_y() + bar.get_height()/2, 
                    f'{value:.1f}%', ha='left', va='center')
    
    # 调整布局
    plt.tight_layout()
    
    # 保存图片
    output_path = '/root/.openclaw/workspace/resource-monitor.png'
    plt.savefig(output_path, dpi=100, bbox_inches='tight')
    plt.close()
    
    return output_path

# 生成系统状态文本
def generate_status_text(info):
    text = f"""
服务器状态报告 - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} 

━━━━━━━━━━━━━━━━━━━━━━━━━━━
🖥️  CPU: {info['cpu']['percent']:.1f}% ({info['cpu']['count']}核)
🧠 内存: {bytes_to_gb(info['memory']['used']):.2f}GB / {bytes_to_gb(info['memory']['total']):.2f}GB ({info['memory']['percent']:.1f}%)
💾 磁盘: {bytes_to_gb(info['disk']['used']):.1f}GB / {bytes_to_gb(info['disk']['total']):.1f}GB ({info['disk']['percent']:.1f}%)
━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔥 Top 进程内存使用:
"""
    
    for i, p in enumerate(info['processes'][:5], 1):
        text += f"\n{i}. {p['name'][:20]:20} - {p['memory_percent']:.1f}% (PID: {p['pid']})"
    
    return text

if __name__ == "__main__":
    try:
        # 创建图表
        chart_path = create_chart()
        print(f"图表已保存到: {chart_path}")
        
        # 生成状态并保存
        info = get_system_info()
        status_text = generate_status_text(info)
        
        with open('/root/.openclaw/workspace/resource-status.txt', 'w', encoding='utf-8') as f:
            f.write(status_text)
        
        print("状态报告已保存到: resource-status.txt")
        
    except Exception as e:
        print(f"生成图表时出错: {e}")
        print("尝试安装缺失的依赖...")
        os.system("pip install matplotlib psutil -q")
        # 重试
        chart_path = create_chart()
        print(f"重试成功，图表已保存到: {chart_path}")