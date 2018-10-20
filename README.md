Run MariaDB with Galera Cluster in Docker
=========================================

This repository contains a Dockerfile which creates a Docker image for
MariaDB with Galera Cluster.

The image is build on top of the existing
[official MariaDB image](https://hub.docker.com/_/mariadb/) on
Docker Hub, which is based on Ubuntu 18.04 LTS.

Building the Docker Image
-------------------------

The image build with this Dockerfile can directly be obtained from
[Docker Hub](https://hub.docker.com/r/hweidner/galera/). If you prefer
to build it on your own, do

	docker build -t hweidner/galera .

Run a Galera cluster based on the image
---------------------------------------

To run the image, provide a Galera config file and a data directory
for each cluster node, and start the nodes.

For the following example, a custom Docker network was created:

	docker network create --subnet 172.18.0.0/16 galera

Three Galera instances will be started using the IP addresses 172.18.0.10X,
with hostnames nodeX and a data directory ```/srv/galera/nodeX``` on the
Docker host, and with the published MariaDB service port set to 331X,
where X is in {1, 2, 3}.

A configuration file for the first node is:

	[mysqld]
	wsrep_cluster_address = "gcomm://172.18.0.101,172.18.0.102,172.18.0.103"
	wsrep_cluster_name    = "galera-cluster"
	wsrep_node_name       = "node1"
	wsrep_node_address    = "172.18.0.101"

For the second and third node, exchange ```wsrep_node_name``` and
```wsrep_node_address``` accordingly.

The directories /srv/galera/node{1,2,3} directories have to be writable
by the ```mysql``` user of the container, which has UID and GID 999.

	mkdir /srv/galera/node{1,2,3}
	chown 999:999 /srv/galera/node{1,2,3}

The first node can now be started with the command

	docker run -d --restart=unless-stopped --net galera \
		--name node1 -h node1 --ip 172.18.0.101 \
		-p 3311:3306 \
		-v /srv/galera/node1.cnf:/etc/mysql/conf.d/galera.cnf \
		-v /srv/galera/node1:/var/lib/mysql \
		-e MYSQL_ROOT_PASSWORD=secret_galera_password \
		-e GALERA_NEW_CLUSTER=1 \
		hweidner/galera

On the second and third node, the command is issued without the
```GALERA_NEW_CLUSTER``` environment variable, thus connecting to the existing
cluster instead of building a new one. The ```MYSQL_ROOT_PASSWORD``` variable
can also be omitted as the node gets the database state from the existing
cluster nodes.

	docker run -d --restart=unless-stopped --net galera \
		--name node2 -h node2 --ip 172.18.0.102 \
		-p 3312:3306 \
		-v /srv/galera/node2.cnf:/etc/mysql/conf.d/galera.cnf \
		-v /srv/galera/node2:/var/lib/mysql \
		hweidner/galera
	
	docker run -d --restart=unless-stopped --net galera \
		--name node3 -h node3 --ip 172.18.0.103 \
		-p 3313:3306 \
		-v /srv/galera/node3.cnf:/etc/mysql/conf.d/galera.cnf \
		-v /srv/galera/node3:/var/lib/mysql \
		hweidner/galera

The Galera cluster nodes are now reachable over the ports 3311, 3312 and
3313 on the hypervisor host. They can be reached from MySQL clients, e.g.

	mysql -h 127.0.0.1 -P 3311 -u root -psecret_galera_password

Note that for a real work cluster, the nodes should be started on
different physical machines. To communicate with each other, the network
setup has to be set up properly, e.g. by running an overlay network,
or by using public IP addresses and exposing the ports needed by Galera
cluster. See the
[Docker overlay network documentation](https://docs.docker.com/network/network-tutorial-overlay/)
and the
[Galera cluster documentation](http://galeracluster.com/documentation-webpages/firewallsettings.html)
for details.

How it works
------------

The Dockerfile deals with the fact that, in Galera
Cluster, the first node has to be started with a special parameter
```--wsrep-new-cluster``` (or a script ```galera_new_cluster```, which
does exactly that).

To achieve this, the Dockerfile adds a temporary file
```/tmp/.wsrep-new-cluster``` to an otherwise unchanged official
MariaDB image. This file is deleted during the first invocation of a
newly instanciated container. Only if this file exists, and if a
non-empty environment variable ```GALERA_NEW_CLUSTER``` was supplied
to the container, the MariaDB server is started with
```--wsrep-new-cluster``` and creates a new cluster.

Whenever a node is restarted, no new cluster will be restarted, because
the file ```/tmp/.wsrep-new-cluster``` is no longer present. Instead,
the node reconnects to the other two cluster nodes.

License
-------

This work is released under the MIT License. See the file LICENSE.txt for
the full text of the license.
