# os



## 安装说明

#### 1.全新安装

默认使用当前主机名作为网页上显示的矿机名称

```sh
curl https://raw.githubusercontent.com/minerx-vip/os-core/refs/heads/main/install.sh | bash -s -- --farm '<FARM_HASH>'

curl https://gitee.com/minerx-vip/os-core/raw/main/install.sh | bash -s -- --farm '<FARM_HASH>'
```



#### 2.全新安装

使用本机 IP 地址作为主机名

适用于例如无盘环境，没有为每台机器设置主机名的情况下，使用 IP 地址的格式来标识每台主机

```sh
curl https://raw.githubusercontent.com/minerx-vip/os-core/refs/heads/main/install.sh | bash -s -- --use_ip_as_hostname --farm '<FARM_HASH>'

curl https://gitee.com/minerx-vip/os-core/raw/main/install.sh | bash -s -- --use_ip_as_hostname --farm '<FARM_HASH>'


```



#### 3.升级现有安装

可以通过以下两种方式来升级现有安装

```sh
## 方式1
curl https://raw.githubusercontent.com/minerx-vip/os-core/refs/heads/main/install.sh | bash
curl https://gitee.com/minerx-vip/os-core/raw/main/install.sh | bash -s -- --use_gitee

## 方式2
os-update
```



