CREATE EXTERNAL TABLE networkData (
  action_time BIGINT, 
  src_ip STRING,
  dest_ip STRING,
  src_port STRING,
  dest_port STRING,
  protocol STRING
) 
PARTITIONED BY (year int, month int, day int, hour int)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION '/data/flume/logs/';
