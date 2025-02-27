#! /bin/bash

# 加密GAME密码
chmod +x /TeaEncrypt
export DNF_DB_GAME_PASSWORD=${DNF_DB_GAME_PASSWORD:0:8}
export DEC_GAME_PWD=`/TeaEncrypt $DNF_DB_GAME_PASSWORD`
echo "game password: $DNF_DB_GAME_PASSWORD"
echo "game pwd key: $DEC_GAME_PWD"

# 清除mysql sock以及pid文件
rm -rf /var/lib/mysql/mysql.sock
rm -rf /var/lib/mysql/*.pid
rm -rf /var/lib/mysql/*.err
# 清除MONITOR_PUBLIC_IP文件
rm -rf /data/monitor_ip/MONITOR_PUBLIC_IP
# 清理日志
rm -rf /home/neople/game/log/siroco11/*
rm -rf /home/neople/game/log/siroco52/*
# 清理/dp2目录
rm -rf /dp2
# 重设supervisor web网页密码
sed -i "s/^username=.*/username=$WEB_USER/" /etc/supervisord.conf
sed -i "s/^password=.*/password=$WEB_PASS/" /etc/supervisord.conf
# 给supervisor扩展文件赋予权限[可用于扩展第三方网关]
mkdir -p /data/conf.d
# 创建DP目录
mkdir -p /data/dp
ln -s /data/dp /dp2
# 创建日志目录
mkdir -p /data/log
mkdir -p /data/log/netbird
# 创建ip监控目录
mkdir -p /data/monitor_ip
# 创建netbird目录
mkdir -p /data/netbird
# 创建频道目录[存放频道脚本]
mkdir -p /data/channel
if [ $(find /data/conf.d -name "*.conf" | wc -l) -gt 0 ]; then
  echo "Add permissions to the extension configuration."
  chmod 777 /data/conf.d/*.conf
else
  echo "Extension configuration not set up."
fi
# 初始化数据
bash /home/template/init/init.sh
error_code=$?
if [ ! $error_code -eq 0 ]; then
  exit -1
fi
# 删除无用文件
rm -rf /home/template/neople-tmp
rm -rf /home/template/root-tmp
mkdir -p /home/neople
# 清理root下文件
rm -rf /root/DnfGateServer
rm -rf /root/GateRestart
rm -rf /root/GateStop
rm -rf /root/run
rm -rf /root/stop
rm -rf /root/Config.ini
rm -rf /root/privatekey.pem

# 复制待使用文件
cp -r /home/template/neople /home/template/neople-tmp
cp -r /home/template/root /home/template/root-tmp
# 修改配置文件
find /home/template/neople-tmp -type f -name "*.cfg" -print0 | xargs -0 sed -i "s/GAME_PASSWORD/$DNF_DB_GAME_PASSWORD/g"
find /home/template/neople-tmp -type f -name "*.cfg" -print0 | xargs -0 sed -i "s/DEC_GAME_PWD/$DEC_GAME_PWD/g"

# 将结果文件拷贝到对应目录[这里是为了保住日志文件目录,将日志文件挂载到宿主机外,因此采用复制而不是mv]
cp -rf /home/template/neople-tmp/* /home/neople
rm -rf /home/template/neople-tmp
# 复制版本文件
cp /data/Script.pvf /home/neople/game/Script.pvf
chmod 777 /home/neople/game/Script.pvf
# 复制等级文件
cp /data/df_game_r /home/neople/game/df_game_r
chmod 777 /home/neople/game/df_game_r
# 复制通讯私钥文件
cp /data/publickey.pem /home/neople/game/
# 为DP目录赋予权限[为了支持更多未知场景, 这里直接给整个目录777权限]
chmod 777 -R /data/dp
# 重置root目录
mv /home/template/root-tmp/* /root/
rm -rf /home/template/root-tmp
chmod 777 /root/*
# 拷贝证书key
cp /data/privatekey.pem /root/
# 构建配置文件软链[不能使用硬链接, 硬链接不可跨设备]
ln -s /data/Config.ini /root/Config.ini
# 替换Config.ini中的GM用户名、密码、连接KEY、登录器版本[这里操作的对象是一个软链接不需要指定-type]
sed -i "s/GAME_PASSWORD/$DNF_DB_GAME_PASSWORD/g" `find /data -name "*.ini"`
sed -i "s/GM_ACCOUNT/$GM_ACCOUNT/g" `find /data -name "*.ini"`
sed -i "s/GM_PASSWORD/$GM_PASSWORD/g" `find /data -name "*.ini"`
sed -i "s/GM_CONNECT_KEY/$GM_CONNECT_KEY/g" `find /data -name "*.ini"`
sed -i "s/GM_LANDER_VERSION/$GM_LANDER_VERSION/g" `find /data -name "*.ini"`

cd /root
# 启动服务
./run
