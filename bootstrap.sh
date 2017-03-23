#!/bin/bash

IP=`ip a s|sed -ne '/127.0.0.1/!{s/^[ \t]*inet[ \t]*\([0-9.]\+\)\/.*$/\1/p}'`
echo "IP:$IP"
mkdir -p /var/log/mesos
mkdir -p /var/log/zookeeper
chown mesos:mesos /var/log/zookeeper
export ZOO_LOG_DIR=/var/log/zookeeper
chown mesos:mesos /var/log/mesos
exec gosu mesos $ZOOKEEPER_HOME/bin/zkServer.sh start &
exec gosu mesos mesos master --zk=zk://localhost:2181/mesos --quorum=1 --log_dir=/var/log/mesos/ --ip=$IP --work_dir=/var/lib/mesos >/dev/null 2>&1 &
exec mesos slave --master=zk://localhost:2181/mesos --log_dir=/var/log/mesos/ --ip=$IP >/dev/null 2>&1 &

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

if [[ $1 == "-b" ]]; then
  /bin/bash
fi
