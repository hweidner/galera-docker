FROM mariadb:10.3-bionic
MAINTAINER Harald Weidner <hweidner@gmx.net>

RUN touch /tmp/.wsrep-new-cluster
COPY startup.sh /startup.sh

USER 999:999
CMD /startup.sh
