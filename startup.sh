#!/bin/bash

if test -n "$GALERA_NEW_CLUSTER" -a -f /tmp/.wsrep-new-cluster; then
  MARIADB_OPTS="$MARIADB_OPTS --wsrep-new-cluster"
fi

rm -f /tmp/.wsrep-new-cluster
exec /usr/sbin/mysqld $MARIADB_OPTS
