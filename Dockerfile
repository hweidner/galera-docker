FROM mariadb:10.3-bionic
MAINTAINER Harald Weidner <hweidner@gmx.net>

RUN touch /tmp/.wsrep-new-cluster && chown mysql:mysql /tmp/.wsrep-new-cluster
COPY startup.sh /startup.sh

USER mysql:mysql
CMD /startup.sh

