export SPARK_WORKER_MEMORY=2g
export SPARK_WORKER_CORES=1
export SPARK_WORKER_INSTANCES=1
export SPARK_DRIVER_MEMORY=1g
export SPARK_MASTER_IP=master
export SPARK_HOME=/usr/local/spark
export SPARK_LOCAL_DIRS=/usr/local/spark
export SCALA_HOME=/usr/local/scala
export JAVA_HOME=/usr/lib/jvm/jdk
export HADOOP_HOME=/usr/local/hadoop
export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop
export PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/build:$PYTHONPATH
export SPARK_HISTORY_OPTS="-Dspark.history.ui.port=7777 -Dspark.history.retainedApplications=3 -Dspark.history.fs.logDirectory=hdfs://master:9000/tmp/spark/spark_event_log"
