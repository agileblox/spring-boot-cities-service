#!/bin/sh 
set -e
. $APPNAME/ci/scripts/common.sh

create_service()
{
  service_created=0
  EXISTS=`cf services | grep ${1} | wc -l | xargs`
  if [ $EXISTS -eq 0 ]
  then
    cf create-service ${1} ${2} ${3}
    service_created=1
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

  create_service p-service-registry standard $EUREKA_SERVICE_NAME
  if [ $service_created -eq 1 ]
  then
    # Sleep for service registry
    max=12
    number=0
    while [ "$number" -lt $max ]
    do
      echo "Pausing to allow Service Discovery to Initialise.....$number/$max"
      number=`expr $number + 1 `
      sleep 5
    done
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
