# systemd
# 1. Написание сервиса мониторинга
Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig);
Для начала создадим конфигурационный файл в целевой директории /etc/sysconfig .
```ruby
[root@systemD sysconfig]# vi /etc/sysconfig/watchlog
[root@systemD sysconfig]# cat watchlog
# Configuration file for my watchdog service
# Place it to /etc/sysconfig
# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log
[root@systemD sysconfig]# cd ..
[root@systemD etc]# cd ..
[root@systemD /]# vi /var/log/watchlog.log
[root@systemD /]# cd /var/log/
```
пишем скрипт:
```ruby
[root@systemD /]# vi /opt/watchlog.sh
[root@systemD /]# cat /opt/watchlog.sh
#!/bin/bash

WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &> /dev/null
then
    logger "$DATE: The word was found!"
else
    exit 0
fi
```
Дадим права на исполнение
```ruby
[root@systemD /]# chmod +x /opt/watchlog.sh
```
Запишем выдуманные тестовые данные в файл лога /var/log/watchlog.log
```ruby
[root@systemD /]# echo "test ALARM test test"  /var/log/watchlog.log
```
Создём юнит для сервиса (в /etc/systemd/system/):
```ruby
[root@systemD system]# vi watchlog.service
[root@systemD system]# cat watchlog.service
[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
```
Создём юнит файл для таймера:
```ruby
[root@systemD system]# vi watchlog.timer
[root@systemD system]# cat watchlog.timer
[Unit]
Description=Run watchlog script every 30 second

[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service

[Install]
WantedBy=multi-user.target
```
стартанем таймер:
```ruby
[root@systemD system]# systemctl start watchlog.timer
[root@systemD system]# systemctl status watchlog.timer
● watchlog.timer - Run watchlog script every 30 second
   Loaded: loaded (/etc/systemd/system/watchlog.timer; disabled; vendor preset: disabled)
   Active: active (elapsed) since Tue 2020-12-22 14:03:48 UTC; 11s ago

Dec 22 14:03:48 systemD systemd[1]: Started Run watchlog script every 30 second.
```
Проверим что пишется в логах, обнаружим там наше сообщение о находке ключевого слова:
```ruby
[root@systemD system]# tail -f /var/log/messages
Dec 22 13:01:01 localhost systemd: Started Session 5 of user root.
Dec 22 13:19:57 localhost yum[27128]: Installed: tree-1.6.0-10.el7.x86_64
Dec 22 13:20:54 localhost yum[27132]: Installed: gpm-libs-1.20.7-6.el7.x86_64
Dec 22 13:20:54 localhost yum[27132]: Installed: 1:mc-4.8.7-11.el7.x86_64
Dec 22 13:30:43 localhost su: (to root) vagrant on pts/0
Dec 22 14:01:01 localhost systemd: Started Session 6 of user root.
Dec 22 14:03:48 localhost systemd: Started Run watchlog script every 30 second.
Dec 22 14:09:18 localhost systemd: Starting My watchlog service...
Dec 22 14:09:18 localhost root: Tue Dec 22 14:09:18 UTC 2020: The word was found!
Dec 22 14:09:18 localhost systemd: Started My watchlog service.
```
# 2. Переписать init скрипт
```ruby
[root@systemD system]# yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y
```
Но перед этим необходимо раскомментировать строки с переменными в /etc/sysconfig/spawn-fcgi
```ruby
[root@systemD system]# vi /etc/systemd/system/spawn-fcgi.service
[root@systemD system]# cat /etc/sysconfig/spawn-fcgi
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"
```
Создадим Unit файл:
```ruby
[root@systemD system]# vi /etc/systemd/system/spawn-fcgi.service
[root@systemD system]# cat /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
```
Теперь проверим:
```ruby
[root@systemD system]# systemctl start spawn-fcgi
[root@systemD system]# systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2020-12-22 14:12:53 UTC; 5s ago
 Main PID: 15896 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─15896 /usr/bin/php-cgi
           ├─15897 /usr/bin/php-cgi
           ├─15898 /usr/bin/php-cgi
           ├─15899 /usr/bin/php-cgi
           ├─15900 /usr/bin/php-cgi
           ├─15901 /usr/bin/php-cgi
           ├─15902 /usr/bin/php-cgi
           ├─15903 /usr/bin/php-cgi
           ├─15904 /usr/bin/php-cgi
           ├─15905 /usr/bin/php-cgi
           ├─15906 /usr/bin/php-cgi
           ├─15907 /usr/bin/php-cgi
           ├─15908 /usr/bin/php-cgi
           ├─15909 /usr/bin/php-cgi
           ├─15910 /usr/bin/php-cgi
           ├─15911 /usr/bin/php-cgi
           ├─15912 /usr/bin/php-cgi
           ├─15913 /usr/bin/php-cgi
           ├─15914 /usr/bin/php-cgi
           ├─15915 /usr/bin/php-cgi
           ├─15916 /usr/bin/php-cgi
           ├─15917 /usr/bin/php-cgi
           ├─15918 /usr/bin/php-cgi
           ├─15919 /usr/bin/php-cgi
           ├─15920 /usr/bin/php-cgi
           ├─15921 /usr/bin/php-cgi
           ├─15922 /usr/bin/php-cgi
           ├─15923 /usr/bin/php-cgi
           ├─15924 /usr/bin/php-cgi
           ├─15925 /usr/bin/php-cgi
           ├─15926 /usr/bin/php-cgi
           ├─15927 /usr/bin/php-cgi
           └─15928 /usr/bin/php-cgi

Dec 22 14:12:53 systemD systemd[1]: Started Spawn-fcgi startup service by Otus.
```
# 3. Дополнить unit-файл httpd (он же apache) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами;
Скопируем юнит файл и сделаем из него шаблон:
```ruby
[root@systemD system]# cp /usr/lib/systemd/system/httpd.service /etc/systemd/system/httpd@.service
[root@systemD system]# vi /etc/systemd/system/httpd@.service
[root@systemD system]# cat /etc/systemd/system/httpd@.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```
Создадим теперь конфиг файлы
```ruby
[root@systemD system]# vi /etc/sysconfig/httpd-first
[root@systemD system]# cat /etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf
[root@systemD system]# vi /etc/sysconfig/httpd-second
[root@systemD system]# cat /etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf
[root@systemD system]# cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
[root@systemD system]# cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf
```
Для удачного запуска, в конфигурационных файлах должны быть указаны уникальные для каждого экземпляра опции Listen и PidFile. Конфиги можно скопировать и поправить только второй, в нем должны быты след опции:
```ruby
[root@systemD system]# cat /etc/httpd/conf/second.conf | grep -Ev ^#

ServerRoot "/etc/httpd"

Listen 8080
```
Проверим:
```ruby
[root@systemD system]# systemctl start httpd@first
[root@systemD system]# systemctl status httpd@first
● httpd@first.service - The Apache HTTP Server
   Loaded: loaded (/etc/systemd/system/httpd@.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2020-12-22 14:23:23 UTC; 5s ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 15998 (httpd)
   Status: "Processing requests..."
   CGroup: /system.slice/system-httpd.slice/httpd@first.service
           ├─15998 /usr/sbin/httpd -DFOREGROUND
           ├─15999 /usr/sbin/httpd -DFOREGROUND
           ├─16000 /usr/sbin/httpd -DFOREGROUND
           ├─16001 /usr/sbin/httpd -DFOREGROUND
           ├─16002 /usr/sbin/httpd -DFOREGROUND
           ├─16003 /usr/sbin/httpd -DFOREGROUND
           └─16004 /usr/sbin/httpd -DFOREGROUND

Dec 22 14:23:23 systemD systemd[1]: Starting The Apache HTTP Server...
```
и второй
```ruby
[root@systemD vagrant]# systemctl status httpd@second
● httpd@second.service - The Apache HTTP Server
   Loaded: loaded (/etc/systemd/system/httpd@.service; disabled; vendor preset: disabled)
   Active: active (running) since Thu 2020-12-24 11:56:01 UTC; 28s ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 1201 (httpd)
   Status: "Total requests: 0; Current requests/sec: 0; Current traffic:   0 B/sec"
   CGroup: /system.slice/system-httpd.slice/httpd@second.service
           ├─1201 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─1202 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─1203 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─1204 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─1205 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─1206 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           └─1207 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
```
```ruby
[root@systemD vagrant]# ss -tnulp | grep httpd
tcp    LISTEN     0      128    [::]:80                 [::]:*                   users:(("httpd",pid=1220,fd=4),("httpd",pid=1219,fd=4),("httpd",pid=1218,fd=4),("httpd",pid=1217,fd=4),("httpd",pid=1216,fd=4),("httpd",pid=1215,fd=4),("httpd",pid=1214,fd=4))
tcp    LISTEN     0      128    [::]:8080               [::]:*                   users:(("httpd",pid=1207,fd=4),("httpd",pid=1206,fd=4),("httpd",pid=1205,fd=4),("httpd",pid=1204,fd=4),("httpd",pid=1203,fd=4),("httpd",pid=1202,fd=4),("httpd",pid=1201,fd=4))
```



