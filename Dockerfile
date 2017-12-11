FROM ubuntu:16.04
MAINTAINER Orozco Hsu <orozcohsu@hotmail.com>

USER root 

ENV HADOOP_VERSION   2.7.3
ENV SPARK_VERSION    2.1.0
ENV SCALA_VERSION    2.12.4
ENV ZEPPELIN_VERSION 0.7.1
ENV HIVE_VERSION     2.1.1
ENV FLUME_VERSION    1.8.0

ENV INSTALLATION_PATH  /usr/local
ENV JAVA_HOME          /usr/lib/jvm/jdk
ENV VISIBLE            now 
ENV ZK_HOME            /usr/share/zookeeper
ENV HADOOP_HOME        ${INSTALLATION_PATH}/hadoop 
ENV HADOOP_PREFIX      ${INSTALLATION_PATH}/hadoop
ENV HADOOP_COMMON_HOME ${HADOOP_PREFIX}
ENV HADOOP_HDFS_HOME   ${HADOOP_PREFIX}
ENV HADOOP_MAPRED_HOME ${HADOOP_PREFIX}
ENV HADOOP_YARN_HOME   ${HADOOP_PREFIX} 
ENV HADOOP_CONF_DIR    ${INSTALLATION_PATH}/hadoop/etc/hadoop 
ENV YARN_CONF_DIR      ${INSTALLATION_PATH}/hadoop/etc/hadoop 
ENV SPARK_HOME         ${INSTALLATION_PATH}/spark
ENV SCALA_HOME         ${INSTALLATION_PATH}/scala
ENV ZEPPELIN_HOME      ${INSTALLATION_PATH}/zeppelin
ENV HIVE_HOME          ${INSTALLATION_PATH}/hive
ENV FLUME_HOME         ${INSTALLATION_PATH}/flume
ENV FLUME_CONF_DIR     ${INSTALLATION_PATH}/flume/conf
ENV LANG               en_US.UTF-8

# For OS
RUN apt-get -qqy update && \
    apt-get install -y software-properties-common apt-utils && \
    add-apt-repository -y multiverse && \
    add-apt-repository -y restricted && \
    apt-get install -y --no-install-recommends fonts-arphic-ukai && \
    apt-get clean 
  
RUN apt-get -qqy update && apt-get upgrade -y

# Install Packages 
RUN apt-get install -y -q openssh-server \ 
    ntpdate \
    supervisor \
    python-setuptools \
    python-pip \
    python-pandas \
    wget \
    curl \
    sudo \
    telnet \
    net-tools \
    netcat \
    python-numpy \
    python-scipy \
    git \
    #for R --
    libapparmor1 \
    gdebi-core \
    locales \
    #--
    vim

# Setup Misc.
RUN mkdir /var/run/sshd && \
    mkdir /var/run/mysqld && \
    echo 'root:root' | chpasswd && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd  && \
    ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa && \
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && \
    #for shiny Chinese support
    /bin/bash -c "locale-gen en_US.UTF-8"

COPY conf/ssh-config /root/.ssh/config
COPY conf/zoo.cfg ./zoo.cfg
COPY conf/myid    ./myid

# Install Bigdata Packages
RUN apt-get install -y openjdk-8-jdk maven && \
    ln -s /usr/lib/jvm/java-8-openjdk-amd64 $JAVA_HOME && \
    apt-get install -y zookeeperd && \ 
    mv zoo.cfg /etc/zookeeper/conf && \
    mv myid /etc/zookeeper/conf
	
ADD conf/hadoop-${HADOOP_VERSION}.tar.gz          /tmp/hadoop-${HADOOP_VERSION}.tar.gz 
ADD conf/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz /tmp/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz 
ADD conf/scala-${SCALA_VERSION}.tgz               /tmp/scala-${SCALA_VERSION}.tgz 
ADD conf/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz /tmp/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz 
ADD conf/apache-hive-${HIVE_VERSION}-bin.tar.gz   /tmp/apache-hive-${HIVE_VERSION}-bin.tar.gz
ADD conf/apache-flume-${FLUME_VERSION}-bin.tar.gz /tmp/apache-flume-${FLUME_VERSION}-bin.tar.gz
#for R Chinese support
ADD conf/locale /etc/default/locale

RUN cd /tmp && \
    mv hadoop-${HADOOP_VERSION}.tar.gz/hadoop-${HADOOP_VERSION} ${INSTALLATION_PATH} && \
    rm -rf hadoop-${HADOOP_VERSION}.tar.gz && \ 
    mv spark-${SPARK_VERSION}-bin-hadoop2.7.tgz/spark-${SPARK_VERSION}-bin-hadoop2.7 ${INSTALLATION_PATH} && \
    rm -rf spark-${SPARK_VERSION}-bin-hadoop2.7.tgz && \
    mv scala-${SCALA_VERSION}.tgz/scala-${SCALA_VERSION} ${INSTALLATION_PATH} && \
    rm -rf scala-${SCALA_VERSION}.tgz && \
    mv zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz/zeppelin-${ZEPPELIN_VERSION}-bin-all ${INSTALLATION_PATH} && \
    rm -rf zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz && \
    mv /tmp/apache-hive-${HIVE_VERSION}-bin.tar.gz/apache-hive-${HIVE_VERSION}-bin ${INSTALLATION_PATH} && \
    rm -rf apache-hive-${HIVE_VERSION}-bin.tar.gz && \
    mv apache-flume-${FLUME_VERSION}-bin.tar.gz/apache-flume-${FLUME_VERSION}-bin ${INSTALLATION_PATH} && \
    rm -rf apache-flume-${FLUME_VERSION}-bin.tar.gz && \
    ln -s ${INSTALLATION_PATH}/apache-flume-${FLUME_VERSION}-bin ${INSTALLATION_PATH}/flume && \
    ln -s ${INSTALLATION_PATH}/apache-hive-${HIVE_VERSION}-bin ${INSTALLATION_PATH}/hive && \
    ln -s ${INSTALLATION_PATH}/hadoop-${HADOOP_VERSION} ${INSTALLATION_PATH}/hadoop && \
    ln -s ${INSTALLATION_PATH}/spark-${SPARK_VERSION}-bin-hadoop2.7 ${INSTALLATION_PATH}/spark && \
    ln -s ${INSTALLATION_PATH}/scala-${SCALA_VERSION}  ${INSTALLATION_PATH}/scala && \
    ln -s ${INSTALLATION_PATH}/zeppelin-${ZEPPELIN_VERSION}-bin-all ${INSTALLATION_PATH}/zeppelin


RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/jdk\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

RUN echo "export PATH=$PATH:$HADOOP_PREFIX/bin:$HADOOP_PREFIX/sbin:${INSTALLATION_PATH}/bin:$SPARK_HOME/bin:$SCALA_HOME/bin:$HIVE_HOME/bin:$FLUME_HOME/bin" >> /root/.bashrc

# Install Mysql
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get install -y mysql-server && \
    chown mysql /var/run/mysqld && \
    apt-get install libmysql-java && \
    cp /usr/share/java/mysql-connector-java-5.1.38.jar ${HIVE_HOME}/lib

VOLUME /var/lib/mysql

#for training
COPY conf/create-database.sql  /tmp/create-database.sql
COPY conf/flume-hive-ddl.sql   /tmp/flume-hive-ddl.sql
COPY conf/flume-netcat-ddl.sql /tmp/flume-netcat-ddl.sql
COPY conf/flume-weblog-ddl.sql /tmp/flume-weblog-ddl.sql

RUN mkdir -p /usr/local/zeppelin/log && \
    mkdir -p /tmp//hive/querylog && \
    mkdir -p /tmp//hive/workingtable && \
    mkdir -p /usr/local/hive/log && \
    mkdir -p /usr/local/flume/logs && \
    mkdir -p /usr/local/R/conf && \
    rm /usr/local/zeppelin/lib/jackson-annotations-2.5.0.jar && \
    rm /usr/local/zeppelin/lib/jackson-core-2.5.3.jar && \
    rm /usr/local/zeppelin/lib/jackson-databind-2.5.3.jar && \
    cp /usr/local/spark/jars/jackson-annotations-2.6.5.jar /usr/local/zeppelin/lib && \
    cp /usr/local/spark/jars/jackson-core-2.6.5.jar /usr/local/zeppelin/lib && \
    cp /usr/local/spark/jars/jackson-databind-2.6.5.jar /usr/local/zeppelin/lib && \
    rm /usr/local/zeppelin/lib/hadoop-annotations-2.6.0.jar && \
    rm /usr/local/zeppelin/lib/hadoop-auth-2.6.0.jar && \
    rm /usr/local/zeppelin/lib/hadoop-common-2.6.0.jar && \
    cp /usr/local/spark/jars/hadoop-annotations-2.7.3.jar /usr/local/zeppelin/lib && \
    cp /usr/local/spark/jars/hadoop-auth-2.7.3.jar /usr/local/zeppelin/lib && \
    cp /usr/local/spark/jars/hadoop-common-2.7.3.jar /usr/local/zeppelin/lib && \
    cp ${HADOOP_HOME}/share/hadoop/common/hadoop-common-${HADOOP_VERSION}.jar ${ZEPPELIN_HOME}/interpreter/jdbc/hadoop-common-${HADOOP_VERSION}.jar

COPY conf/core-site.xml                   ${HADOOP_CONF_DIR}/core-site.xml
COPY conf/hdfs-site.xml                   ${HADOOP_CONF_DIR}/hdfs-site.xml
COPY conf/mapred-site.xml                 ${HADOOP_CONF_DIR}/mapred-site.xml
COPY conf/yarn-site.xml                   ${HADOOP_CONF_DIR}/yarn-site.xml
COPY conf/capacity-scheduler.xml          ${HADOOP_CONF_DIR}/capacity-scheduler.xml
COPY conf/spark-env.sh                    ${SPARK_HOME}/conf/spark-env.sh
COPY conf/spark-default.conf              ${SPARK_HOME}/conf/spark-default.conf
COPY conf/zeppelin-env.sh                 ${ZEPPELIN_HOME}/conf/zeppelin-env.sh
COPY conf/zeppelin-site.xml               ${ZEPPELIN_HOME}/conf/zeppelin-site.xml
COPY conf/setup.R                         ${ZEPPELIN_HOME}/R/conf/setup.R
COPY conf/hive-site.xml                   ${HIVE_HOME}/conf/hive-site.xml
COPY conf/hive-env.sh                     ${HIVE_HOME}/conf/hive-env.sh
COPY conf/hive-log4j2.properties          ${HIVE_HOME}/conf/hive-log4j2.properties
COPY conf/beeline-log4j2.properties       ${HIVE_HOME}/conf/beeline-log4j2.properties
COPY conf/agent.properties                ${FLUME_HOME}/conf/agent.properties
COPY conf/agent.properties.hive           ${FLUME_HOME}/conf/agent.properties.hive
COPY conf/agent.properties.netcat         ${FLUME_HOME}/conf/agent.properties.netcat
COPY conf/agent.properties.weblog         ${FLUME_HOME}/conf/agent.properties.weblog
COPY conf/profiles.json                   /tmp/profiles.json
COPY conf/log-generator.py                /tmp/log-generator.py 
COPY conf/gen-events.py                   /tmp/gen-events.py
COPY conf/CSVSerializer.jar               ${FLUME_HOME}/lib/CSVSerializer.jar
COPY conf/hive-jdbc-${HIVE_VERSION}.jar   ${HIVE_HOME}/lib/hive-jdbc-${HIVE_VERSION}.jar
COPY conf/hive-jdbc-${HIVE_VERSION}.jar   ${ZEPPELIN_HOME}/interpreter/jdbc/hive-jdbc-${HIVE_VERSION}.jar
COPY conf/mysql-connector-java-5.1.38.jar ${ZEPPELIN_HOME}/interpreter/jdbc/mysql-connector-java-5.1.38.jar
COPY conf/flume-hive.data                 /tmp/flume-hive.data
COPY conf/README.md                       /tmp/README.md
#for training
COPY conf/log-flume-1.sh                  /tmp/log-flume-1.sh
COPY conf/log-weblog.py                   /tmp/log-weblog.py
COPY conf/weblog-map.csv                  /tmp/weblog-map.csv
COPY conf/iris.csv                        /tmp/iris.csv
COPY conf/airbnb-listings.csv             /tmp/airbnb-listings.csv
COPY conf/pyspark01.csv                   /tmp/pyspark01.csv
COPY conf/CHANGES.txt                     /tmp/CHANGES.txt
#--

# Install rJava & R packages
RUN apt-get -qqy  update && apt-get -y -q install r-cran-rjava r-base r-base-dev && \
    wget https://download2.rstudio.org/rstudio-server-1.1.383-amd64.deb && \ 
    gdebi -n rstudio-server-1.1.383-amd64.deb && \
    adduser --disabled-password --gecos "" guest && \ 
    echo "guest:guest"|chpasswd && \
    wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb && \
    R -e "install.packages(c('shiny', 'rmarkdown'), repos='https://cran.rstudio.com/')" && \
    cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server && \
    R CMD javareconf && \
    Rscript --vanilla ${ZEPPELIN_HOME}/R/conf/setup.R

# SSH port
EXPOSE 22 
	
# HDFS port
EXPOSE 9000 50070 

# YARN port
EXPOSE 8040 8042 8088 8030 8031 8032 8033 

# Hive port
EXPOSE 10000 10002 9083 9000 

# Mysql port
EXPOSE 3306

# FLUME port
EXPOSE 5566

# SPARK port
EXPOSE 8080 4040 4041 4042 4043 7777

# ZEPPELIN port
EXPOSE 18080

# RSTUDIO SHINY
EXPOSE 8787 3838

# Start ssh 
COPY conf/startup.sh ${INSTALLATION_PATH}/bin/startup.sh
RUN chmod +x ${INSTALLATION_PATH}/bin/startup.sh

CMD ["startup.sh"]


