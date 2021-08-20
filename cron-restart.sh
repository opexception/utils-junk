#!/bin/bash

Message_Body="
Please check ese-jenkins.\n
No java process was found.\n
\n
Launch jenkins with the following command:\n
nohup /etc/alternatives/java -Dcom.sun.akuma.Daemon=daemonized -Djava.awt.headless=true -Xms3g -Xmx3g -DJENKINS_HOME=/proj/esejenkins/home -jar /usr/lib/jenkins/jenkins.war --logfile=/var/log/jenkins/jenkins.log --webroot=/var/cache/jenkins/war --daemon --httpPort=8080 --debug=5 --handlerCountMax=100 --handlerCountMaxIdle=20 --debug=5 > /proj/esejenkins/console.out"

if java_pid=$(/usr/bin/pgrep java)
    then exit
    else
        echo -e ${Message_Body} | /usr/bin/mail -s "Service Down: ese-jenkins" robert.maracle@analog.com
        # /sbin/service jenkins start
fi

## logrotate config to prevent nohup from filling /proj/esejenkins
## /etc/logrotate.d/jenkins-console
# /proj/esejenkins/console.out {
#     missingok
#     notifempty
#     size 15M
#     daily
#     rotate 50
#     mail robert.maracle@analog.com
#     compress
#     delaycompress
#     extension log
#     create 0644 root uscad
# }
