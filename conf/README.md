# Run docker container
docker run -h master -it --rm --name iii \
  -e "NODE_TYPE=master" \
  -e "AUTHORIZED_SSH_PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)" \
  -v /tmp/docker-cluster-hadoop-name/:/data/dfs/name/ \
  -v /tmp/docker-cluster-hadoop-data/:/data/dfs/data/ \
  -v /tmp/docker-cluster-hadoop-logs/:/usr/local/hadoop/logs/ \
  -v /tmp/docker-cluster-zookeeper-logs/:/var/log/zookeeper/ \
  -v /tmp/docker-cluster-zeppelin-logs/:/usr/local/zeppelin/log \
  -p 8088:8088 -p 50070:50070 -p 9000:9000 -p 2222:22 -p 8080:8080 \ 
  -p 18080:18080 -p 10000:10000 -p 10002:10002 -p 9083:9083 -p 3306:3306 \
  -p 4040:4040 -p 4041:4041 -p 4042:4042 -p 4043:4043 -p 8787:8787 -p 3838:3838 \
  orozcohsu/ha-sp-ze-zo-hi-fl-rs

# Start Spark context in container
spark-shell --master spark://master:7077

# Navigate Spark-history in port 7777
http://master:7777 

# Start Hive
hive --service hiveserver2 --hiveconf hive.server2.thrift.port=10000 --hiveconf hive.root.logger=INFO,console

# Start Beeline
beeline -u jdbc:hive2://master:10000 -n hive -p hive

# Beeline ACID table query
set hive.support.concurrency=true; set hive.enforce.bucketing=true; set hive.exec.dynamic.partition.mode=nonstrict; set hive.txn.manager=org.apache.hadoop.hive.ql.lockmgr.DbTxnManager; set hive.compactor.initiator.on=true; set hive.compactor.worker.threads=1; 


# Start Hive Metastore
hive --service metastore &

# Start Flume-ng
$FLUME_HOME/bin/flume-ng agent -conf-file $FLUME_CONF_DIR/agent.properties -name agent1 --classpath "/usr/local/hive/hcatalog/share/hcatalog/*":"/usr/local/hive/lib/*"  

# Run netcat to flume port 5566
python gen-events.py | netcat localhost 5566 

# Alter table for netcat test
./gen-events.py 2>&1 | nc 127.0.0.1 5566
ALTER TABLE networkData ADD PARTITION (year='2017',month='11',day='21',hour='08');
