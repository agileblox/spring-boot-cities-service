#!/bin/sh 
set -e
. $APPNAME/ci/scripts/common.sh

create_service()
{
  EXISTS=`cf services | grep ${1} | wc -l | xargs`
  if [ $EXISTS -eq 0 ]
  then
    cf create-service ${1} ${2} ${3}
  fi
}

main()
{
  cf_login 
  summaryOfServices
  EXISTS=`cf services | grep ${DB_SERVICE_NAME} | wc -l | xargs`
  if [ $EXISTS -eq 0 ]
  then
    PLAN=`cf marketplace -s p-mysql | grep MB | head -n 1 | cut -d ' ' -f1 | xargs`
    if [ -z $PLAN ]
    then
      PLAN=`cf marketplace -s p-mysql | grep MySQL | head -n 1 | cut -d ' ' -f1 | xargs`
    fi
    cf create-service p-mysql $PLAN ${DB_SERVICE_NAME}
  fi

  EXISTS=`cf services | grep ${EUREKA_SERVICE_NAME} | wc -l | xargs`
  if [ $EXISTS -eq 0 ]
  then
    create_service p-service-registry standard $EUREKA_SERVICE_NAME
    STATUS=`cf service $EUREKA_SERVICE_NAME | grep Status`
    while [[ $STATUS == *"progress"* ]]
    do
      STATUS=`cf service $EUREKA_SERVICE_NAME | grep Status`
      echo $EUREKA_SERVICE_NAME ":" $STATUS
      sleep 2.5
    done
    if [[ $STATUS == *"failed"* ]]
    then
      echo_msg "Could not create Service Discovery service"
      exit 1
    fi
  fi
  summaryOfServices
  cf logout
}

trap 'abort $LINENO' 0
SECONDS=0
SCRIPTNAME=`basename "$0"`
main
printf "\nExecuted $SCRIPTNAME in $SECONDS seconds.\n"
trap : 0
