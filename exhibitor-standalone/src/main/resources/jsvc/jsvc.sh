#!/bin/sh
### BEGIN INIT INFO
# Provides:          exhibitor
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: RGS
# Description:       Starts Exhibitor service
### END INIT INFO

# Setup variables
BASE_DIR="/home/dev/exhibitor"
COMMON_DIR="/home/dev/exhibitor"
EXEC="/usr/bin/jsvc"
JAVA_HOME="$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")"
JAVA_OPTS=""
COMPONENT_NAME="exhibitor-standalone-1.5.3-SNAPSHOT-jar-with-dependencies"
COMPONENT_PARAMS="--configtype zookeeper --zkconfigconnect localhost:2181 --zkconfigzpath /exhibitor"

CLASS_PATH="$COMMON_DIR/conf:$BASE_DIR/conf:$COMMON_DIR/lib/*:$BASE_DIR/$COMPONENT_NAME.jar"
CLASS="com.netflix.exhibitor.application.DaemonMain"

USER="dev"
PID="$BASE_DIR/pid/server.pid"
LOG_OUT="$COMMON_DIR/log/exhibitor-server.out"
LOG_ERR="$COMMON_DIR/log/exhibitor-server.err"

do_exec()
{
    ulimit -Hn 8192
    ulimit -Sn 8192
    mkdir -p "$BASE_DIR/log"
    chmod -R 0644 "$BASE_DIR/log"
    chown -R $USER "$BASE_DIR"
    cd $BASE_DIR
    $EXEC -home "$JAVA_HOME" -verbose -cp $CLASS_PATH $JAVA_OPTS -user $USER -outfile $LOG_OUT -errfile $LOG_ERR -pidfile $PID $CLASS $COMPONENT_PARAMS $1
}


case "$1" in
     status)
        if [ -f "$PID" ]; then
          if ! ps $(cat $PID) > /dev/null; then
            rm -f "$PID"
            echo "exhibitor-standalone is NOT running (removed pid file $PID)."
            exit 4
          else
            echo "exhibitor-standalone is running (pid $(cat $PID))."
            exit 0
          fi
        else
          echo "exhibitor-standalone is NOT running."
          exit 3
        fi
            ;;

    start)
        do_exec
            ;;
    stop)
        echo "Stopping exhibitor-standalone..."
        do_exec "-stop"
        sleep 15
        if [ -f "$PID" ]; then
            echo "PID file still exists. Will forcefully stop service."
            SID=$(ps -o sid= $(cat $PID) | sed -e 's/^[ \t]*//')
            kill -9 "$(cat $PID)"
            kill -9 $SID
            rm -f $PID
        fi
        echo "The exhibitor-standalone has stopped"
            ;;
    restart)
        if [ -f "$PID" ]; then
            do_exec "-stop"
            sleep 15
            if [ -f "$PID" ]; then
              SID=$(ps -o sid= $(cat $PID) | sed -e 's/^[ \t]*//')
              kill -9 "$(cat $PID)"
              kill -9 $SID
              rm -f $PID
            fi
		fi
        do_exec
            ;;
    *)
            echo "usage: daemon {start|stop|restart|status}" >&2
            exit 3
            ;;
esac