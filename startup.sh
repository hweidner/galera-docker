#!/bin/bash

CMD="/usr/local/bin/docker-entrypoint.sh mysqld"

if test -n "$GALERA_NEW_CLUSTER" -a -f /tmp/.wsrep-new-cluster; then
  CMD="$CMD --wsrep-new-cluster"
fi

rm -f /tmp/.wsrep-new-cluster
exec $CMD

