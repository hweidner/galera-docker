Run MariaDB with Galera Cluster in Docker
=========================================

This repository contains a Dockerfile which creates a Docker image for
MariaDB with Galera Cluster.

Building the Docker Image
-------------------------

Build the container image (you can skip this step and use the pre-built
image from Docker Hub):

	docker build -t hweidner/galera .

Run a Galera cluster based on the image
---------------------------------------

To run the image, provide a Galera config file and a data directory
for each cluster node, and start the first node.

For the following example, a custom Docker network was created:

	docker network create --ip-range 172.18.0.0/16 galera

Three Galera instances will be started using the IP addresses 172.18.0.10X,
with hostnames nodeX and a data directory ```/srv/galera/nodeX``` on the
Docker host, and with the published MariaDB service port set to 331X,
where X is in {1, 2, 3}.

A configuration file for the first node is:

	[mysqld]
	binlog_format=ROW
	default_storage_engine=InnoDB
	innodb_autoinc_lock_mode=2
	innodb_flush_log_at_trx_commit=2
	innodb_buffer_pool_size=122M
	innodb_doublewrite=1
	wsrep_provider=/usr/lib/libgalera_smm.so
	wsrep_cluster_address="gcomm://172.18.0.101,172.18.0.102,172.18.0.103"
	wsrep_sst_method=rsync
	wsrep_cluster_name="galera-cluster"
	wsrep_node_name=node1
	wsrep_node_address="172.18.0.101"
	wsrep_on=ON

For the second and third node, exchange ```wsrep_node_name``` and
```wsrep_node_address``` accordingly.

The nodes can now be started with the command

	docker run -d --restart=unless-stopped --net galera \
		--name node1 -h node1 --ip 172.18.0.101 \
		-p 3311:3306 \
		-v /srv/galera/node1.cnf:/etc/mysql/conf.d/galera.cnf \
		-v /srv/galera/node1:/var/lib/mysql \
		-e MYSQL_ROOT_PASSWORD=secret_galera_password \
		-e GALERA_NEW_CLUSTER=1 \
		hweidner/galera

On the second and third node, the command is issued without the
```GALERA_NEW_CLUSTER``` environment variable, and of course with
IP address, node name, published port number, config file name and
data directory set to the values for node2 and node3.

How it works
------------

The Dockerfile deals with the fact that, in Galera
Cluster, the first node has to be started with a special parameter
```--wsrep-new-cluster``` (or a script ```galera_new_cluster```, which
does exactly that).

To achieve this, the Dockerfile adds a temporary file
```/tmp/.wsrep-new-cluster``` to an otherwise unchanged official
Galera image. This file is deleted during the first invocation. Only
if this file exists, and if a non-empty environment variable
```GALERA_NEW_CLUSTER``` was supplied to the container, the MariaDB
server is started with ```--wsrep-new-cluster``` and creates a new
cluster.

Whenever a node is restarted, no new cluster will be restarted, because
the file ```/tmp/.wsrep-new-cluster``` is no longer present. Instead,
the node reconnects to the other two cluster nodes.
