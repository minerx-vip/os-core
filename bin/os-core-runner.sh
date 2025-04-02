#!/bin/bash

# 设置错误处理
set -e

# 加载颜色库
source /os/bin/colors

# 创建必要的目录
mkdir -p /var/log/os/

# 将脚本的输出重定向到日志文件
exec > >(tee -a /var/log/os/os-core-runner.log) 2>&1

echoCyan "====================== $(date) ======================"
echoCyan "开始执行 os-core-runner.sh"

# 检查是否已有 os-core-daemon 进程在运行
if pgrep -f "os-core-daemon.sh" > /dev/null; then
    echoCyan "os-core-daemon 已经在运行中，结束旧的进程..."
    pkill -f "os-core-daemon.sh" || true
    sleep 1
fi

# 清理所有 Dead 状态的 screen 会话
echoCyan "清理旧的 screen 会话..."
screen -wipe > /dev/null 2>&1 || true

# 结束现有的 screen 会话
for session in os-core-master say-hello say-stats; do
    if screen -ls | grep -q "$session"; then
        echoCyan "结束旧的 $session 会话..."
        screen -S "$session" -X quit > /dev/null 2>&1 || true
    fi
done

# 创建循环脚本
echoCyan "创建循环脚本..."
cat > /os/bin/os-core-daemon.sh << 'EOF'
#!/bin/bash

# 设置错误处理
set -e

# 创建日志目录
mkdir -p /var/log/os/

# 记录开始时间
echo "$(date) - os-core-daemon 启动" > /var/log/os/os-core-daemon.log
echo "PID: $$" >> /var/log/os/os-core-daemon.log

# 循环运行 os-core
while true; do
    echo "$(date) - 启动 os-core 服务..." >> /var/log/os/os-core-daemon.log
    
    # 运行 os-core
    if [ -x /os/bin/os-core ]; then
        echo "$(date) - 运行 os-core..." >> /var/log/os/os-core-daemon.log
        /os/bin/os-core >> /var/log/os/os-core-daemon.log 2>&1 || echo "$(date) - os-core 执行出错" >> /var/log/os/os-core-daemon.log
    else
        echo "$(date) - /os/bin/os-core 不存在或没有执行权限" >> /var/log/os/os-core-daemon.log
    fi
    
    echo "$(date) - 服务完成，5分钟后再次运行" >> /var/log/os/os-core-daemon.log
    sleep 300
done
EOF

# 设置执行权限
chmod +x /os/bin/os-core-daemon.sh

# 使用 nohup 在后台运行循环脚本
echoCyan "启动 os-core-daemon 服务..."

# 使用 disown 确保进程不会被终止
/os/bin/os-core-daemon.sh > /var/log/os/os-core-daemon.nohup 2>&1 &
DAEMON_PID=$!
disown $DAEMON_PID

# 记录进程 ID
echo $DAEMON_PID > /var/run/os-core-daemon.pid

# 等待几秒，检查进程是否还在运行
sleep 2
if ps -p $DAEMON_PID > /dev/null; then
    echoCyan "os-core-daemon 已启动成功，进程 ID: $DAEMON_PID"
else
    echoRed "错误：os-core-daemon 启动失败！"
    cat /var/log/os/os-core-daemon.nohup
fi

echoCyan "日志文件位于 /var/log/os/os-core-daemon.log"
echoCyan "完成执行 os-core-runner.sh"