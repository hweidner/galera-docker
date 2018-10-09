FROM mariadb:10.3-bionic
MAINTAINER Harald Weidner <hweidner@gmx.net>

RUN touch /tmp/.wsrep-new-cluster && chown -R mysql:mysql /tmp/.wsrep-new-cluster
COPY galera.cnf /etc/mysql/conf.d/01-galera.cnf
COPY startup.sh /startup.sh

USER mysql:mysql
CMD /startup.sh

