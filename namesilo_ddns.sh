#!/bin/bash
# namesilo dns update script

# confs

# domain
DOMAIN="domain.com"
# api_key
API_KEY="123klhad123j"
# records_api
RECORDS_API="https://www.namesilo.com/api/dnsListRecords?version=1&type=xml&key=${API_KEY}&domain=${DOMAIN}"
# log_dir
LOG_DIR="/root"
# file_dir
FILE_DIR="/root"
# ipv4 network card name
WAN_NAME="pppoe-wan"

# main
# get current ipv4
CUR_IP=`ifconfig $WAN_NAME | awk -F '[ :]+' '/inet addr/ {print $4}'`
# get last ipv4
if [ -e "${FILE_DIR}/last_ip.txt" ]
then
  LASTEST_IP=`cat "${FILE_DIR}/last_ip.txt"`
else
  LASTEST_IP="no_ip"
fi
# check the ipv4 change
if [ $CUR_IP != $LASTEST_IP ]
then
  for RECORD in `curl -s $RECORDS_API | awk 'BEGIN{RS="<resource_record>";} NR > 1 {print $0}'`
  do
    eval `echo $RECORD | awk -F '</?[A-Za-z0-9_]+(><[A-Za-z0-9_]+)?>' '{printf("RRID=%s;HOST=%s;VALUE=%s",$2,$4,$5)}'`
    UPDATE_API="https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=xml&key=${API_KEY}&domain=${DOMAIN}&rrid=${RRID}&rrvalue=${CUR_IP}&rrttl=3600"
    if [ $HOST != $DOMAIN ]
    then
      UPDATE_API=`echo $HOST | awk -F '.' -vapi=${UPDATE_API} '{print api"&rrhost="$1}'`
    fi
    RES=`curl -s $UPDATE_API | awk -F '</?code>' '{print $2}'`
    if [ $RES == "300" ]
    then
      echo "["$(date "+%Y-%m-%d %H:%M:%S")"]" "${HOST} update successfully!" >> "${LOG_DIR}/success.log"
    else
      echo "["$(date "+%Y-%m-%d %H:%M:%S")"]" "${HOST} update failed!" >> "${LOG_DIR}/fail.log"
    fi
  done
  echo $CUR_IP > "${FILE_DIR}/last_ip.txt"
fi

