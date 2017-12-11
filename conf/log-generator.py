#!/usr/bin/python
import time
import random

def buildURL():
    # build random URL
    url_list=['www.pchome.com.tw', 'www.yahoo.com', 'www.momo.com.tw','www.ebay.com','www.amazon.com','www.udn.com.tw','ww.shopee.tw','www.etmall.com.tw']
    return random.choice(url_list)

def buildPath():
    # build random Path
    path_list=['/mobile/iphone.html', '/mobile/htc.html', '/mobile/samsung.html', '/mobile/mi.html','/mobile/oppo.html','/mobile/acer.html','/mobile/sony.html','/mobile/nokia.html','/mobile/blackberry.html','/mobile/lg.html','/mobile/sharp.html','/mobile/asus.html','/mobile/gplus.html','/mobile/motorola.html','/mobile/panasonic.html']
    return random.choice(path_list)

def buildHTTP():
    # build random HTTP code
    a=200
    b=599
    return random.randrange(a,b,1)

def getHTTP():
    # build random HTTP status
    HTTP_status = [ 100, 101, 102, 200, 201, 202, 203, 204, 205, 206, 207, 226, 300, 301, 302, 400, 401, 402, 500, 501, 502 ]
    return random.choice(HTTP_status)

def buildIP():
    # build random IP
    b1 = random.randrange(0, 255, 1)
    b2 = random.randrange(0, 255, 1)
    b3 = random.randrange(0, 255, 1)
    b4 = random.randrange(0, 255, 1)
    return str(b1) + '.' + str(b2) + '.' + str(b3) + '.' + str(b4)

#log_File = open('/tmp/log-generator.log', 'w')

count = 0

while True:
  if(count > 100):
    count = 0;
    time.sleep(30); 
  else:
    Http = getHTTP()
    count = count + 1
    Http = str(Http)
    Url = buildURL()
    Path = buildPath()
    Ip = str(buildIP())

    line = "HTTP %s,%s%s,%s\n"%(Http,Url,Path,Ip)
    print line
    with open('/tmp/log-generator.log', 'a') as log:
        log.write(line)


