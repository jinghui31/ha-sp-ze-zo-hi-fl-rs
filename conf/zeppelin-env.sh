#!/bin/bash

export JAVA_HOME=/usr/lib/jvm/jdk
export SPARK_HOME=/usr/local/spark
export HADOOP_HOME=/usr/local/hadoop
export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop
export ZEPPELIN_INTP_JAVA_OPTS="-XX:PermSize=512M -XX:MaxPermSize=1024M"
export ZEPPELIN_CONF_DIR=/usr/local/zeppelin/conf
export ZEPPELIN_LOG_DIR=/usr/local/zeppelin/log
export ZEPPELIN_HOME=/usr/local/zeppelin
export PATH=$JAVA_HOME/bin:$PATH
export PATH=$SPARK_HOME/bin:$PATH
export PATH=$HADOOP_HOME/bin:$PATH

