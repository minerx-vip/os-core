# os


#### 安装教程

```
## 全新安装 - 默认使用当前主机名作为网页上显示的矿机名称
curl https://gitee.com/xiaoliuxiao6/os/raw/master/install.sh | bash -s -- --farm '<FARM_HASH>'

## 全新安装 - 使用本机 IP 地址作为主机名
## 适用于例如无盘环境，没有为每台机器设置主机名的情况下，使用 IP 地址的格式来标识每台主机
curl https://gitee.com/xiaoliuxiao6/os/raw/master/install.sh | bash -s -- --use_ip_as_hostname --farm '<FARM_HASH>'

## 升级现有安装
curl https://gitee.com/xiaoliuxiao6/os/raw/master/install.sh | bash
```

