#!/usr/bin/python
import time
import random
import string
from datetime import date, datetime

def getHost():
    # random host
    url_list=['http://www.pchome.com.tw/mobile.php']
    return random.choice(url_list)

def getPath():
    # random path
    path_list=['?page=iphone', '?page=htc', '?page=samsung', '?page=mi','?page=oppo','?page=acer','?page=sony','?page=nokia','?page=blackberry','?page=lg','?page=sharp','?page=asus','?page=gplus','?page=motorola','?page=panasonic']
    return random.choice(path_list)

def getUuid(length):
   # uuid 
   letters = string.ascii_lowercase
   return ''.join(random.choice(letters) for i in range(length))
        
def getDt():
    now = datetime.now()
    dt=now.strftime("%Y-%m-%d %H:%M:%S")
    return dt

count = 0

while True:
  if(count > 100):
    count = 0;
    time.sleep(30); 
  else:
    count = count + 1
    host = getHost()
    path = getPath()
    uuid = getUuid(1)+'AaBbCcDd'
    dt = getDt()

    line = "%s,%s%s,%s"%(dt,host,path,uuid)
    print line
    with open('/tmp/log-weblog.log', 'a') as log:
        log.write(line)


