#!/bin/sh 
. $APPNAME/ci/scripts/common.sh

searchForCity()
{
  running=`curl -s $URL/cities/search/name?q=Aldermoor | grep "SU3915"`
  exitIfNull $running
}

main()
{
  cf_login

  summaryOfApps
  createVarsBasedOnVersion
  echo $CF_APPNAME
  checkSpringBootAppOnPCF $CF_APPNAME
  searchForCity

  cf logout
}

trap 'abort $LINENO' 0
SECONDS=0
SCRIPTNAME=`basename "$0"`
main
printf "\nExecuted $SCRIPTNAME in $SECONDS seconds.\n"
trap : 0
