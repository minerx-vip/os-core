#!/bin/bash

# 加载颜色库
source /os/bin/colors

# 创建必要的目录
mkdir -p /var/log/os/

# 检查是否已有 os-core-daemon 进程在运行
if pgrep -f "os-core-daemon.sh" > /dev/null; then
    echoCyan "os-core-daemon 已经在运行中，结束旧的进程..."
    pkill -f "os-core-daemon.sh"
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

# 创建日志目录
mkdir -p /var/log/os/

# 循环运行 os-core
while true; do
    echo "$(date) - 启动 os-core 服务..." >> /var/log/os/os-core-daemon.log
    /os/bin/os-core >> /var/log/os/os-core-daemon.log 2>&1
    echo "$(date) - os-core 服务完成，10秒后再次运行" >> /var/log/os/os-core-daemon.log
    sleep 10
done
EOF

# 设置执行权限
chmod +x /os/bin/os-core-daemon.sh

# 使用 nohup 在后台运行循环脚本
echoCyan "启动 os-core-daemon 服务..."
nohup /os/bin/os-core-daemon.sh > /var/log/os/os-core-daemon.nohup 2>&1 &

# 记录进程 ID
echo $! > /var/run/os-core-daemon.pid

echoCyan "os-core-daemon 已启动，进程 ID: $!"
echoCyan "日志文件位于 /var/log/os/os-core-daemon.log"