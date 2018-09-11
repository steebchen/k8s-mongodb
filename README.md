# MongoDB Deployment Demo for self-hosted Kubernetes

An example project demonstrating the deployment of a MongoDB Replica Set via Kubernetes on your own cluster.

For further background information on the original repo and what these scripts and resource files do, plus general information about running MongoDB with Kubernetes, see: [http://k8smongodb.net/](http://k8smongodb.net/)

By default, a simple host path mapping `/data` is used – if you don't want that, you can simply adapt the config in resources/mongodb.

For a better overall config, please check the work from the original author at [http://k8smongodb.net/](http://k8smongodb.net/).

## 1 How To Run

### 1.1 Prerequisites

Ensure you have a running Kubernetes cluster accessible from the `kubectl` command.

### 1.2 Main Deployment Steps

1. To create a Kubernetes cluster, create the required disk storage, and deploy the MongoDB Service (including the StatefulSet running "mongod" containers), via a command-line terminal/shell:

```bash
$ sh scripts/generate.sh
```

2. Execute the following script which connects to the first Mongod instance running in a container of the Kubernetes StatefulSet, via the Mongo Shell, to (1) initialise the MongoDB Replica Set, and (2) create a MongoDB admin user (specify the password you want as the argument to the script, replacing 'abc123').

```bash
$ sh scripts/configure_repset_auth.sh abc123
```

You should now have a MongoDB Replica Set initialised, secured and running in a Kubernetes Stateful Set. You can view the list of Pods that contain these MongoDB resources, by running the following:

```bash
$ kubectl get pods
```

The running replica set members will be accessible to any "app tier" containers, that are running in the same Kubernetes cluster, via the following hostnames and ports (remember to also specify the username and password, when connecting to the database):

```bash
mongod-0.mongo.default.svc.cluster.local:27017
mongod-1.mongo.default.svc.cluster.local:27017
mongod-2.mongo.default.svc.cluster.local:27017
```

### 1.3 Example Tests To Run To Check Things Are Working

Use this section to prove:

1. Data is being replicated between members of the containerised replica set.
2. Data is retained even when the MongoDB Service/StatefulSet is removed and then re-created (by virtue of re-using the same Persistent Volume Claims).

#### 1.3.1 Replication Test

Connect to the container running the first "mongod" replica, then use the Mongo Shell to authenticate and add some test data to a database:

```bash
$ kubectl exec -it mongod-0 -c mongod-container bash
$ mongo
> db.getSiblingDB('admin').auth("main_admin", "abc123");
> use test;
> db.testcoll.insert({a:1});
> db.testcoll.insert({b:2});
> db.testcoll.find();
```

Exit out of the shell and exit out of the first container (“mongod-0”). Then connect to the second container (“mongod-1”), run the Mongo Shell again and see if the previously inserted data is visible to the second "mongod" replica:

```bash
$ kubectl exec -it mongod-1 -c mongod-container bash
$ mongo
> db.getSiblingDB('admin').auth("main_admin", "abc123");
> use test;
> db.setSlaveOk(1);
> db.testcoll.find();
```

You should see that the two records inserted via the first replica, are visible to the second replica.

#### 1.3.2 Redeployment Without Data Loss Test

To see if Persistent Volume Claims really are working, run a script to drop the Service & StatefulSet (thus stopping the pods and their “mongod” containers) and then a script to re-create them again:

```bash
$ sh scripts/delete_service.sh
$ sh scripts/recreate_service.sh
$ kubectl get all
```

Keep re-running the final command above, until you can see that all 3 “mongod” pods and their containers have been successfully started again. Then connect to the first container, run the Mongo Shell and query to see if the data we’d inserted into the old containerised replica-set is still present in the re-instantiated replica set:

```bash
$ kubectl exec -it mongod-0 -c mongod-container bash
$ mongo
> db.getSiblingDB('admin').auth("main_admin", "abc123");
> use test;
> db.testcoll.find();
```

You should see that the two records inserted earlier, are still present.

### 1.4 Undeploying & Cleaning Down the Kubernetes Environment

Run the following script to undeploy the MongoDB Service & StatefulSet plus related Kubernetes resources:

```bash
$ sh teardown.sh
```

## 2 Factors Addressed By This Project

* Deployment of a MongoDB on your own Kubernetes cluster
* Use of Kubernetes StatefulSets and fixed Volumes to ensure data is not lost when containers are recycled
* Proper configuration of a MongoDB Replica Set for full resiliency
* Securing MongoDB by default for new deployments
* Leveraging XFS filesystem for data file storage to improve performance
* Controlling CPU & RAM Resource Allocation
* Correctly configuring WiredTiger Cache Size in containers
* Controlling Anti-Affinity for Mongod Replicas to avoid a Single Point of Failure
