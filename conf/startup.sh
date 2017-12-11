#!/bin/bash

HOSTS_FILE_TMP=/tmp/hosts

MASTER_HOST=${MASTER_HOST:-master}
MASTER_IP=${MASTER_IP:-0.0.0.0}
NODE_TYPE=${NODE_TYPE:-node}
SLAVES=${SLAVES:-localhost}
NODE_MANAGER_WEB_PORT=${NODE_MANAGER_WEB_PORT:-8042}

sed -i -e "s|@MASTER_IP@|${MASTER_HOST}|g" ${HADOOP_CONF_DIR}/yarn-site.xml
sed -i -e "s|@NODE_MANAGER_WEB_PORT@|${NODE_MANAGER_WEB_PORT}|g" ${HADOOP_CONF_DIR}/yarn-site.xml
sed -i -e "s|@MASTER_IP@|${MASTER_HOST}|g" ${HADOOP_CONF_DIR}/core-site.xml


if [ -f "$HOSTS_FILE_TMP" ]; then
    cat $HOSTS_FILE_TMP >> /etc/hosts
fi

echo "${MASTER_IP} ${MASTER_HOST}" >> /etc/hosts

# Start Service
service ssh start

# Misc.
chmod +x /tmp/log-generator.py
chmod +x /tmp/gen-events.py
chmod +x /tmp/log-weblog.py
ln -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime
pip install netaddr

# root ssh key
echo $AUTHORIZED_SSH_PUBLIC_KEY >> /root/.ssh/authorized_keys
if [ ${NODE_TYPE} == "master" ]; then
    echo "" > ${HADOOP_CONF_DIR}/slaves
    hosts=(${SLAVES//,/ })
    for i in "${hosts[@]}"
        do 
            echo $i >> ${HADOOP_CONF_DIR}/slaves
        done
    echo "Formating namenode..."
    $HADOOP_PREFIX/bin/hdfs namenode -format -nonInteractive
    echo "Starting ZOOKEEPER..."
    $ZK_HOME/bin/zkServer.sh start
    echo "Starting HDFS..."
    $HADOOP_PREFIX/sbin/start-dfs.sh
    echo "Starting YARN..."
    $HADOOP_PREFIX/sbin/start-yarn.sh
    echo "Starting SPARK..."
    $SPARK_HOME/sbin/start-all.sh
    echo "Starting ZEPPELIN..."
    $ZEPPELIN_HOME/bin/zeppelin-daemon.sh start
    echo "Starting MYSQL..."
    /etc/init.d/mysql start
    /usr/bin/mysql -u root < /tmp/create-database.sql
    /usr/bin/mysql -u root -e "CREATE USER 'hive'@'localhost' IDENTIFIED BY 'hive';"
    /usr/bin/mysql -u root -e "REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'hive'@'localhost';"
    /usr/bin/mysql -u root -e "GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES,EXECUTE ON metastore_db.* TO 'hive'@'localhost';"
    /usr/bin/mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'hive'@'localhost' IDENTIFIED BY 'hive' WITH GRANT OPTION;"
    /usr/bin/mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'hive'@'%' IDENTIFIED BY 'hive' WITH GRANT OPTION;"
    /usr/bin/mysql -u root -e "FLUSH PRIVILEGES;"
    echo "Starting Hive metastore init... "
    $HIVE_HOME/bin/schematool -dbType mysql -initSchema    
    echo "Starting HIVESERVER2 at port 10000 ..."
    $HIVE_HOME/bin/hive --service hiveserver2 --hiveconf hive.server2.thrift.port=10000 --hiveconf hive.root.logger=INFO,console &>/dev/null &
    echo "Starting Hive metastore at port 9083... "
    $HIVE_HOME/bin/hive --service metastore &>/dev/null &
    echo "Starting FLUME..."
    $FLUME_HOME/bin/flume-ng agent -conf-file $FLUME_CONF_DIR/agent.properties -name agent1 --classpath "/usr/local/hive/hcatalog/share/hcatalog/*":"/usr/local/hive/lib/*" &>/dev/null &
    echo "Starting log-generator, the random log will be saved in /tmp/log-generator.log... "
    python /tmp/log-generator.py &>/dev/null &
    echo "Starting gen-events.py, the random log will be saved in /tmp/replay-log.txt... "
    python /tmp/gen-events.py &>/dev/null &
    echo "Starting log-weblog.py, the random log will be saved in /tmp/log-weblog.log..."
    python /tmp/log-weblog.py &>/dev/null &
    echo "Starting Spark-history service..."
    $SPARK_HOME/sbin/start-history-server.sh hdfs://master:9000/tmp/spark/spark_event_log &>/dev/null &
    echo "Starting Rstudio-server service..."
    /usr/lib/rstudio-server/bin/rstudio-server start  &>/dev/null &
elif [ ${NODE_TYPE} == "slave" ]; then
    $HADOOP_PREFIX/sbin/hadoop-daemon.sh start datanode
    $HADOOP_PREFIX/sbin/yarn-daemon.sh start nodemanager
fi

# Keep container running
#supervisord -n

# Create training HDFS folders
echo "Creating HDFS folders..."
${HADOOP_HOME}/bin/hadoop fs -mkdir /tmp &>/dev/null
${HADOOP_HOME}/bin/hadoop fs -mkdir /hive &>/dev/null
${HADOOP_HOME}/bin/hadoop fs -mkdir /data &>/dev/null
${HADOOP_HOME}/bin/hadoop fs -put   /tmp/profiles.json /data &>/dev/null
${HADOOP_HOME}/bin/hadoop fs -put   /tmp/pyspark01.csv /tmp &>/dev/null
${HADOOP_HOME}/bin/hadoop fs -mkdir /data/flume &>/dev/null
${HADOOP_HOME}/bin/hadoop fs -mkdir /data/flume/logs &>/dev/null
${HADOOP_HOME}/bin/hadoop fs -mkdir /tmp/spark &>/dev/null
${HADOOP_HOME}/bin/hadoop fs -mkdir /tmp/spark/spark_event_log &>/dev/null
${HADOOP_HOME}/bin/hadoop fs -chmod g+w /tmp &>/dev/null
${HADOOP_HOME}/bin/hadoop fs -chmod g+w /hive &>/dev/null
${HADOOP_HOME}/bin/hadoop fs -chmod g+w /data &>/dev/null
${HADOOP_HOME}/bin/hadoop fs -chmod g+w /data/flume &>/dev/null
${HADOOP_HOME}/bin/hadoop fs -chmod g+w /data/flume/logs &>/dev/null
${HADOOP_HOME}/bin/hadoop fs -chmod g+w /tmp/spark &>/dev/null
${HADOOP_HOME}/bin/hadoop fs -chmod g+w /tmp/spark/spark_event_log &>/dev/null

# Create training table
echo "Creating training tables..."
$HIVE_HOME/bin/beeline -u jdbc:hive2://master:10000/default -n hive -p hive -f /tmp/flume-netcat-ddl.sql;
$HIVE_HOME/bin/beeline -u jdbc:hive2://master:10000/default -n hive -p hive -f /tmp/flume-hive-ddl.sql;
$HIVE_HOME/bin/beeline -u jdbc:hive2://master:10000/default -n hive -p hive -f /tmp/flume-weblog-ddl.sql;

# Shiny-server 
mkdir -p /var/log/shiny-server
chown shiny.shiny /var/log/shiny-server
exec shiny-server 2>&1 &

# logs
tail -n 1000 -f $HADOOP_PREFIX/logs/*

