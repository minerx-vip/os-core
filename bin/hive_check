#!/usr/bin/env bash

all_gone=true


###########################################################################
## 检查服务
###########################################################################
# 检查服务是否存在
if systemctl list-unit-files | grep -q "^${SERVICE_NAME}.service"; then
    # 服务存在，检查状态
    STATUS=$(systemctl is-active "$SERVICE_NAME")
    if [[ "$STATUS" != "active" ]]; then
        echo "服务 $SERVICE_NAME 存在，但未在运行状态：$STATUS"
    else
        echo "服务 $SERVICE_NAME 正在运行"
        all_gone=false
    fi
fi


###########################################################################
## 检查 screen 会话
###########################################################################
targets=("agent" "autofan")
existing_screens=$(screen -ls | grep Detached | awk -F '.' '{print $2}' | awk '{print $1}')

for target in "${targets[@]}"; do
    if echo "$existing_screens" | grep -q "^${target}$"; then
        echo "❌ screen 会话仍存在：$target"
        all_gone=false
    else
        echo "✅ screen 会话已消失：$target"
    fi
done
