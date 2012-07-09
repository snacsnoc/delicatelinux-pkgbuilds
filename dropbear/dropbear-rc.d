#!/bin/bash
daemon_name=dropbear

. /etc/rc.conf

. /etc/conf.d/$daemon_name

daemon_args="-p $DROPBEAR_PORT"
[ ! -z $DROPBEAR_BANNER ] && daemon_args="$daemon_args -b $DROPBEAR_BANNER"
[ ! -z $DROPBEAR_DSSKEY ] && daemon_args="$daemon_args -d $DROPBEAR_DSSKEY"
[ ! -z $DROPBEAR_RSAKEY ] && daemon_args="$daemon_args -r $DROPBEAR_RSAKEY"
[ ! -z $DROPBEAR_EXTRA_ARGS ] && daemon_args="$daemon_args $DROPBEAR_EXTRA_ARGS"

get_pid() {
        pidof $daemon_name
}

case "$1" in
  start)
    echo "Starting $daemon_name Daemon"
    PID=$(get_pid)
    if [ -z "$PID" ]; then
      echo "Checking for hostkeys"
      if [ ! -z $DROPBEAR_DSSKEY ]; then
        [ ! -f $DROPBEAR_DSSKEY ] && dropbearkey -t dss -f $DROPBEAR_DSSKEY
      fi;
      if [ ! -z $DROPBEAR_RSAKEY ]; then
        [ ! -f $DROPBEAR_RSAKEY ] && dropbearkey -t rsa -f $DROPBEAR_RSAKEY
      fi;

      [ -f /var/run/$daemon_name.pid ] && rm -f /var/run/$daemon_name.pid # Cleanup zombie pid files.
      $daemon_name $daemon_args # Make it Go Joe!
      if [ $? -gt 0 ]; then
        echo "Daemon has failed to start"
        exit 1
      else
        echo $(get_pid) > /var/run/$daemon_name.pid
      fi
    else
      echo "Daemon has failed to start"
      exit 1
    fi
    ;;

  stop)
    echo "Stopping $daemon_name Daemon..."

    PID=$(get_pid)
    [ ! -z "$PID" ]  && kill $PID &> /dev/null # Be dead (please), I say!
    if [ $? -gt 0 ]; then
      echo "Daemon has failed to stop"
      exit 1
    else
      rm -f /var/run/$daemon_name.pid &> /dev/null
    fi
    ;;

  restart)
    $0 stop
    sleep 3
    $0 start
    ;;

  fingerprint)
    echo "Fingerprinting $daemon_name hostkeys"
    if [ ! -z $DROPBEAR_DSSKEY ]; then
      echo "DSS/DSA Key $(dropbearkey -y -f $DROPBEAR_DSSKEY | grep Fingerprint)"      
    fi;
    if [ ! -z $DROPBEAR_RSAKEY ]; then
      echo "RSA Key $(dropbearkey -y -f $DROPBEAR_RSAKEY | grep Fingerprint)"
    fi;
  ;;

  *)
    echo "usage: $0 {start|stop|restart|fingerprint}"  
esac
exit 0
